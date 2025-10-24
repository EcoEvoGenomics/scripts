#!/usr/bin/python
"""
Slurm job cost estimator: parse SBATCH headers, normalize resources, and
calculate/print per-queue costs for single jobs and arrays.

Developed with GPT-UiO (GPT-5).

Overview:
    - Extracts '#SBATCH' options from a Slurm script and normalizes aliases.
    - Parses walltime, CPU layout, memory, and job array specification.
    - Computes CPU-hours and memory-hours per queue, then the charged cost
      as max(CPU-hours, memory-hours × queue factor).
    - Prints a readable, colorized cost breakdown and a banner warning
      if costs meet/exceed a threshold.

Key behaviors:
    - Time formats: D-HH:MM:SS, HH:MM:SS, MM:SS, or minutes (integer).
    - CPUs: ntasks × cpus-per-task (defaults to 1 × 1 if unspecified); also
      supports tasks-per-node × nodes as a fallback to derive ntasks.
    - Memory parsing: accepts short (K/M/G/T), long (KB/MB/GB/TB), and binary
      (KiB/MiB/GiB/TiB) suffixes; outputs GiB per task. If --mem is absent,
      uses --mem-per-cpu × CPUs.
    - Arrays: supports '--array' specs like '0-9', '1,3,5', '1-10:2', '0-99%10';
      throttling (%N) affects concurrency only, not total count.

Queues and costs:
    - Normal, bigmem, and hugemem queues use fixed memory cost factors.
    - For each queue, charged cost = max(CPU-hours, Memory-hours × factor).
    - For array jobs, totals scale linearly by array_count.

CLI usage:
    python slurm_cost.py /path/to/slurm_script.sh

Outputs:
    - Recommended queue based on lowest charged cost (per task if not an array,
      total if array_count > 1).
    - Per-task and (if array) total CPU-hours, memory-hours, and charged costs.
    - Optional warning banner when maximum charged cost ≥ threshold.
"""

import argparse
import re
import textwrap

def extract_slurmheader_arguments(slurmscript_path):

    """
    Parse '#SBATCH' header lines into a canonical dict of SBATCH options.

    Returns:
        dict[str, str]: Normalized keys (e.g., 'time', 'ntasks', 'mem', 'array') mapped to string values.

    Notes:
        - Supports '--key=value' and '--key value', long and short forms.
        - Normalizes aliases via SLURMARG_CONVERSIONS (e.g., '-m' -> 'mail-type').
        - Strips surrounding quotes; last occurrence wins.
        - Raises ValueError if a value contains '#'.
    """

    SLURMHEADER_PATTERN = re.compile(
        r"""
        ^\s*\#SBATCH\s+
        (?:
            --(?P<slurmarg_long>[A-Za-z0-9_-]+) # Match long argument names
            | -(?P<slurmarg_short>[A-Za-z])     # Match short argument names
        )
        (?:
            =(?P<argvalue_eq>(?=[^\r\n]*\S)[^\r\n]+)     # Obtain argument values after =
            | \s+(?P<argvalue_sp>(?=[^\r\n]*\S)[^\r\n]+) # Obtain argument values after space
        )
        $
        """,
        re.MULTILINE | re.VERBOSE
    )

    SLURMARG_CONVERSIONS = {
        'c': 'cpus-per-task',
        'n': 'ntasks',
        'N': 'nodes',
        't': 'time',
        'J': 'job-name',
        'o': 'output',
        'e': 'error',
        'A': 'account',
        'p': 'partition',
        'm': 'mail-type',
        'cpus-per-task': 'cpus-per-task',
        'ntasks': 'ntasks',
        'ntasks-per-node': 'ntasks-per-node',
        'tasks-per-node': 'ntasks-per-node',
        'nodes': 'nodes',
        'time': 'time',
        'time-min': 'time-min',
        'job-name': 'job-name',
        'output': 'output',
        'error': 'error',
        'account': 'account',
        'partition': 'partition',
        'nodelist': 'nodelist',
        'qos': 'qos',
        'mail-type': 'mail-type',
        'mail-user': 'mail-user',
        'mem': 'mem',
        'mem-per-cpu': 'mem-per-cpu',
        'array': 'array'
    }

    scriptlines = open(slurmscript_path, "r").read()
    headerlines = SLURMHEADER_PATTERN.finditer(scriptlines)

    slurmargs = {}
    for line in headerlines:

        slurmarg = line.group('slurmarg_long') or line.group('slurmarg_short')
        slurmarg = SLURMARG_CONVERSIONS.get(slurmarg, slurmarg)

        argvalue = line.group('argvalue_eq') or line.group('argvalue_sp')
        argvalue = argvalue.strip()
        
        argvalue_contains_hash = argvalue.find("#") != -1
        if argvalue_contains_hash:
            raise ValueError(f"Illegal '#' in value for option '{slurmarg}': {argvalue}")

        argvalue_is_quoted = len(argvalue) >= 2 and argvalue[0] == argvalue[-1] and argvalue[0] in "'\""
        if argvalue_is_quoted:
            unquoted_argvalue = argvalue[1:-1].strip()
            argvalue = unquoted_argvalue
        
        slurmargs[slurmarg] = argvalue

    return(slurmargs)

def parse_slurmargs(slurmargs):
    """
    Normalize SBATCH options to per-task resource metrics and array size.

    Returns:
        dict: {
            'hours': float,     # walltime (hours)
            'cpus': int,        # CPUs per task
            'memory_gb': float, # GiB per task
            'array_count': int, # number of array tasks (1 if none)
        }

    Raises:
        ValueError: If time or memory cannot be parsed.
    """

    def parse_argument_to_int(argument):

        if not argument:
            return None
        
        try:
            return int(argument)
        except ValueError:
            return None

    def parse_time_to_hours(time_argument):

        if not time_argument:
            return None
        
        timestring = time_argument.strip()

        # D-HH:MM:SS
        timestring_dhhmmss = re.fullmatch(r'(\d+)-(\d{1,2}):(\d{1,2}):(\d{1,2})', timestring)
        if timestring_dhhmmss:
            days, hours, minutes, seconds = map(int, timestring_dhhmmss.groups())
            return days * 24 + hours + minutes / 60.0 + seconds / 3600.0
        
        # HH:MM:SS
        timestring_hhmmss = re.fullmatch(r'(\d+):(\d{1,2}):(\d{1,2})', timestring)
        if timestring_hhmmss:
            hours, minutes, seconds = map(int, timestring_hhmmss.groups())
            return hours + minutes / 60.0 + seconds / 3600.0
        
        # MM:SS
        timestring_mmss = re.fullmatch(r'(\d+):(\d{1,2})', timestring)
        if timestring_mmss:
            minutes, seconds = map(int, timestring_mmss.groups())
            return minutes / 60.0 + seconds / 3600.0
        
        # MM
        timestring_mm = re.fullmatch(r'\d+', timestring)
        if timestring_mm:
            minutes = int(timestring)
            return minutes / 60.0
        
        return None

    def parse_mem_to_gigabytes(memory_argument):
        
        BYTES_IN_KILOBYTE = 1024

        if not memory_argument:
            return None
        
        memstring = memory_argument.strip()

        # Accept '16000', '16000M', '16G', '2T'
        memargs = re.fullmatch(r'(?i)\s*(\d+(?:\.\d+)?)\s*([kmgt](?:i?b)?|)\s*', memstring)
        if not memargs:
            return None
        
        # Unit is case-insensitive
        unit = (memargs.group(2) or '').lower()
        amount = int(memargs.group(1))

        if unit == 'k' or unit == "kb" or unit == "gib":
            return round(amount * (BYTES_IN_KILOBYTE ** 1) / (BYTES_IN_KILOBYTE ** 3), 4)
        if unit == 'm' or unit == "mb" or unit == "gib":
            return round(amount * (BYTES_IN_KILOBYTE ** 2) / (BYTES_IN_KILOBYTE ** 3), 4)
        if unit == 'g' or unit == "gb" or unit == "gib":
            return round(amount * (BYTES_IN_KILOBYTE ** 3) / (BYTES_IN_KILOBYTE ** 3), 4)
        if unit == 't' or unit == "tb" or unit == "gib":
            return round(amount * (BYTES_IN_KILOBYTE ** 4) / (BYTES_IN_KILOBYTE ** 3), 4)
        
        return None
    
    def parse_array_count(array_spec):
        """
        Parse Slurm --array specification and return total number of array tasks.
        Supports:
          - Comma-separated items: '1,3,5'
          - Ranges: '0-9'
          - Ranges with step: '1-10:2'
          - Throttling: '%N' (ignored for count), e.g., '0-99%10'
          - Mixed: '1,4-8,10-20:5%2'
        Returns 1 if array_spec is empty or unparsable.
        """
        if not array_spec:
            return 1
        spec = array_spec.strip()
        total = 0
        try:
            for part in spec.split(','):
                part = part.strip()
                if not part:
                    continue
                # Remove throttling (e.g., '%10')
                part = part.split('%', 1)[0]

                # Range with optional step 'start-end[:step]'
                if '-' in part:
                    rng, step_str = (part.split(':', 1) + ['1'])[:2]
                    start_str, end_str = rng.split('-', 1)
                    start = int(start_str)
                    end = int(end_str)
                    step = int(step_str)
                    if step <= 0:
                        step = 1
                    if end < start:
                        # Slurm expects increasing ranges; if reversed, treat as 1
                        total += 1
                    else:
                        count = ((end - start) // step) + 1
                        total += count
                else:
                    # Single index
                    int(part)  # validate
                    total += 1
        except Exception:
            # If anything goes wrong, default to 1
            return 1

        return total if total > 0 else 1

    ntasks = parse_argument_to_int(slurmargs.get('ntasks'))
    if ntasks is None:
        tasks_per_node = parse_argument_to_int(slurmargs.get('tasks-per-node'))
        nodes = parse_argument_to_int(slurmargs.get('nodes'))
        if tasks_per_node is None or nodes is None:
            ntasks = 1
        else:
            ntasks = tasks_per_node * nodes
    cpus_per_task = parse_argument_to_int(slurmargs.get('cpus-per-task'))
    if cpus_per_task is None:
        cpus_per_task = 1
    cpus = ntasks * cpus_per_task

    hours = parse_time_to_hours(slurmargs.get('time'))
    if hours is None:
        raise ValueError("Invalid Slurm script: Time cannot be unspecified.")
    
    memory_gigabytes = parse_mem_to_gigabytes(slurmargs.get('mem'))
    if memory_gigabytes is None:
        mem_per_cpu_bytes = parse_mem_to_gigabytes(slurmargs.get('mem-per-cpu'))
        if mem_per_cpu_bytes is None:
            raise ValueError("Invalid Slurm script: Memory cannot be unspecified.")
        memory_gigabytes = mem_per_cpu_bytes * cpus
    
    return {
        'hours': hours,
        'cpus': cpus,
        'memory_gb': memory_gigabytes,
        'array_count': parse_array_count(slurmargs.get('array'))
    }

def calculate_sbatch_jobcost_per_queue(parsed_slurmargs):
    """
    Compute per-queue costs for a single array task and totals across the array.

    Returns:
        dict: {
            'array_count': int,
            'per_task': {
                'cpu_hours': float,
                'mem_hours': {'normal': float, 'bigmem': float, 'hugemem': float},
                'charged':   {'normal': float, 'bigmem': float, 'hugemem': float},
            },
            'total': {
                'cpu_hours': float,
                'mem_hours': {'normal': float, 'bigmem': float, 'hugemem': float},
                'charged':   {'normal': float, 'bigmem': float, 'hugemem': float},
            },
        }
    """
    # Queue memory cost factors
    NORMAL_QUEUE_MEMORY_FACTOR = 0.2577031
    BIGMEM_QUEUE_MEMORY_FACTOR = 0.1104972
    HUGEMEM_QUEUE_MEMORY_FACTOR = 0.01059603

    def calculate_cpu_hours(hours, cpus):
        return cpus * hours
    
    def calculate_mem_hours(hours, mem_gb, queue_factor):
        return mem_gb * hours * queue_factor

    hours = float(parsed_slurmargs.get('hours', 0.0))
    cpus = int(parsed_slurmargs.get('cpus', 0))
    memory_gb = float(parsed_slurmargs.get('memory_gb', 0.0))
    array_count = int(parsed_slurmargs.get('array_count', 1))

    # Per-task (i.e., per array element) costs
    per_task_cpu_hours = calculate_cpu_hours(hours, cpus)
    per_task_mem_normal = calculate_mem_hours(hours, memory_gb, NORMAL_QUEUE_MEMORY_FACTOR)
    per_task_mem_bigmem = calculate_mem_hours(hours, memory_gb, BIGMEM_QUEUE_MEMORY_FACTOR)
    per_task_mem_hugemem = calculate_mem_hours(hours, memory_gb, HUGEMEM_QUEUE_MEMORY_FACTOR)

    per_task_charged_normal = max(per_task_cpu_hours, per_task_mem_normal)
    per_task_charged_bigmem = max(per_task_cpu_hours, per_task_mem_bigmem)
    per_task_charged_hugemem = max(per_task_cpu_hours, per_task_mem_hugemem)

    # Total across all array tasks
    total_cpu_hours = per_task_cpu_hours * array_count
    total_mem_normal = per_task_mem_normal * array_count
    total_mem_bigmem = per_task_mem_bigmem * array_count
    total_mem_hugemem = per_task_mem_hugemem * array_count

    total_charged_normal = per_task_charged_normal * array_count
    total_charged_bigmem = per_task_charged_bigmem * array_count
    total_charged_hugemem = per_task_charged_hugemem * array_count

    return {
        'hours': hours,
        'cpus': cpus,
        'memory_gb': memory_gb,
        'array_count': array_count,

        'per_task': {
            'cpu_hours': per_task_cpu_hours,
            'mem_hours': {
                'normal': per_task_mem_normal,
                'bigmem': per_task_mem_bigmem,
                'hugemem': per_task_mem_hugemem,
            },
            'charged': {
                'normal': per_task_charged_normal,
                'bigmem': per_task_charged_bigmem,
                'hugemem': per_task_charged_hugemem,
            },
        },

        'total': {
            'cpu_hours': total_cpu_hours,
            'mem_hours': {
                'normal': total_mem_normal,
                'bigmem': total_mem_bigmem,
                'hugemem': total_mem_hugemem,
            },
            'charged': {
                'normal': total_charged_normal,
                'bigmem': total_charged_bigmem,
                'hugemem': total_charged_hugemem,
            },
        },
    }


def print_cost_details(cost_details, threshold=10000):
    """
    Pretty-print per-task costs, and if array_count > 1, totals across all tasks.
    Warn with a banner if the maximum charged cost (per-task or total) ≥ threshold.

    Parameters:
        cost_details (dict): Output of calculate_sbatch_jobcost_per_queue.
        threshold (float): CPU-hours threshold for warning.
    """

    def stylise_string(string, color = None, bold = False):
        codes = []
        if bold:
            codes.append("1")
        if color == "green":
            codes.append("32")
        elif color == "yellow":
            codes.append("33")
        elif color == "red":
            codes.append("31")
        elif color == "cyan":
            codes.append("36")
        elif color == "magenta":
            codes.append("35")
        elif color == "blue":
            codes.append("34")
        if not codes:
            return string
        return f"\033[{';'.join(codes)}m{string}\033[0m"

    def format_number(num, digits=2):
        return f"{num:,.{digits}f}"

    def print_warning_banner(message, title = "WARNING", color = "red", bold = True, width = None, padding = 3, stylise_fn = None):
        if width is None:
            width = 60
        width = max(40, min(width, 120))
        tl, tr, bl, br, h, v = "┌", "┐", "└", "┘", "─", "│"
        inner_width = width - 2
        content_width = inner_width - (padding * 2)
        title_text = f" {title} "
        left_len = (inner_width - len(title_text)) // 2
        right_len = inner_width - len(title_text) - left_len
        title_line = f"{tl}{h * left_len}{title_text}{h * right_len}{tr}"
        lines = []
        for para in str(message).splitlines() or [""]:
            wrapped = textwrap.wrap(para, width=content_width) or [""]
            lines.extend(wrapped)
        def style(s):
            return stylise_fn(s, color, bold=bold) if stylise_fn else s
        print(style(title_line))
        for line in lines:
            text = line.ljust(content_width)
            print(style(f"{v}{' ' * padding}{text}{' ' * padding}{v}"))
        print(style(f"{bl}{h * inner_width}{br}"))

    CPU_HOUR_MARKET_PRICE_NOK = 0.13

    hours = int(cost_details.get('hours', 1))
    cpus = int(cost_details.get('cpus', 1))
    memory_gb = int(cost_details.get('memory_gb', 1))
    array_count = int(cost_details.get('array_count', 1))

    # Per-task values
    cpu_hours_task = float(cost_details['per_task']['cpu_hours'])
    mem_hours_task = {
        'normal': float(cost_details['per_task']['mem_hours']['normal']),
        'bigmem': float(cost_details['per_task']['mem_hours']['bigmem']),
        'hugemem': float(cost_details['per_task']['mem_hours']['hugemem'])
    }
    charged_task = {
        'normal': float(cost_details['per_task']['charged']['normal']),
        'bigmem': float(cost_details['per_task']['charged']['bigmem']),
        'hugemem': float(cost_details['per_task']['charged']['hugemem'])
    }
    cheapest_queue = min(charged_task, key=charged_task.get)
    cheapest_cost = charged_task[cheapest_queue]
    most_expensive_queue = max(charged_task, key=charged_task.get)
    most_expensive_cost = charged_task[most_expensive_queue]

    # Array total values
    if array_count > 1:
        cpu_hours_total = float(cost_details['total']['cpu_hours'])
        mem_hours_total = {
            'normal': float(cost_details['total']['mem_hours']['normal']),
            'bigmem': float(cost_details['total']['mem_hours']['bigmem']),
            'hugemem': float(cost_details['total']['mem_hours']['hugemem'])
        }
        charged_total = {
            'normal': float(cost_details['total']['charged']['normal']),
            'bigmem': float(cost_details['total']['charged']['bigmem']),
            'hugemem': float(cost_details['total']['charged']['hugemem'])
        }
        cheapest_cost = charged_total[cheapest_queue]
        most_expensive_cost = charged_total[most_expensive_queue]

    # Header
    print(stylise_string("\n================= Saga Job Cost Report =====================\n", bold=True))
    
    # Warnings for expensive jobs
    if most_expensive_cost >= threshold:
        warning_msg = (
            "\nThis job can be expensive!\n\n"
            f"Highest possible cost: {format_number(most_expensive_cost)} CPU-hours\n"
            f"On queue: {most_expensive_queue}\n"
            f"Expense: {format_number(most_expensive_cost * CPU_HOUR_MARKET_PRICE_NOK)} NOK at market price\n\n"
            "Consider reducing walltime, CPUs, or requested memory, or choosing a different queue. "
            "Carefully inspect the calculated cost also on the cheapest queue. It could be unacceptably high as well.\n\n"
        )
        print_warning_banner(warning_msg, stylise_fn=stylise_string)
        print()

    # Cheapest queue
    reccomendation_msg = (
        f"\nCheapest cost: {format_number(cheapest_cost)} CPU-hours"
        f"\nOn queue: {cheapest_queue}\n"
        f"Expense: {format_number(cheapest_cost * CPU_HOUR_MARKET_PRICE_NOK)} NOK at market price\n\n"
    )
    print_warning_banner(reccomendation_msg, title = "CHEAPEST QUEUE", color = "green", stylise_fn = stylise_string)
    print()

    print(stylise_string("================= Basic ====================================\n", bold=True))
    
    # Resource request
    print("- Your requested resource allocation\n")
    print(f"    • time per task (hrs)  : {stylise_string(hours, 'blue', bold = True)}")
    print(f"    • cpus per task        : {stylise_string(cpus, 'blue', bold = True)}")
    print(f"    • memory per task (gb) : {stylise_string(memory_gb, 'blue', bold = True)}")
    print(f"    • array size (tasks)   : {stylise_string(array_count, 'blue', bold = True)}")
    print()

    # Charged cost per queue (max of CPU vs memory)
    if array_count > 1:
        print("- Cost in CPU-hours on each queue\n")
        print(f"    • {stylise_string('normal', bold = True)}")
        print(f"      per task : {stylise_string(format_number(charged_task['normal']), 'blue', bold = True)}")
        print(f"      total    : {stylise_string(format_number(charged_total['normal']), 'blue', bold = True)}")
        print(f"    • {stylise_string('bigmem', bold = True)}")
        print(f"      per task : {stylise_string(format_number(charged_task['bigmem']), 'blue', bold = True)}")
        print(f"      total    : {stylise_string(format_number(charged_total['bigmem']), 'blue', bold = True)}")
        print(f"    • {stylise_string('hugemem', bold = True)}")
        print(f"      per task : {stylise_string(format_number(charged_task['hugemem']), 'blue', bold = True)}")
        print(f"      total    : {stylise_string(format_number(charged_total['hugemem']), 'blue', bold = True)}")
        print()

    else:
        print("- Cost in CPU-hours on each queue\n")
        print(f"    • {stylise_string('normal', bold = True)} : {stylise_string(format_number(charged_task['normal']), 'blue', bold = True)}")
        print(f"    • {stylise_string('bigmem', bold = True)} : {stylise_string(format_number(charged_task['bigmem']), 'blue', bold = True)}")
        print(f"    • {stylise_string('hugemem', bold = True)}: {stylise_string(format_number(charged_task['hugemem']), 'blue', bold = True)}")
        print()
    
    print(f"- NB: These are the costs of submitting your script {stylise_string('once', 'red', bold = True)}.\n")

    print(stylise_string("================= Advanced =================================\n", bold=True))
    # CPU-hours
    if array_count > 1:
        print(f"- CPU-hours occupied by requested CPUs:\n")
        print(f"    • per task : {stylise_string(format_number(cpu_hours_task), 'blue', bold = True)}")
        print(f"    • total    : {stylise_string(format_number(cpu_hours_total), 'blue', bold = True)}\n")
    else:
        print(f"- CPU-hours occupied by requested CPUs: {stylise_string(format_number(cpu_hours_task), 'blue', bold=True)}\n")

    # Memory-hours per queue
    if array_count > 1:
        print("- CPU-hours occupied by requested memory (per queue)\n")
        print(f"    • {stylise_string('normal', bold = True)}")
        print(f"      per task : {stylise_string(format_number(mem_hours_task['normal']), 'blue', bold = True)}")
        print(f"      total    : {stylise_string(format_number(mem_hours_total['normal']), 'blue', bold = True)}")
        print(f"    • {stylise_string('bigmem', bold = True)}")
        print(f"      per task : {stylise_string(format_number(mem_hours_task['bigmem']), 'blue', bold = True)}")
        print(f"      total    : {stylise_string(format_number(mem_hours_total['bigmem']), 'blue', bold = True)}")
        print(f"    • {stylise_string('hugemem', bold = True)}")
        print(f"      per task : {stylise_string(format_number(mem_hours_task['hugemem']), 'blue', bold = True)}")
        print(f"      total    : {stylise_string(format_number(mem_hours_total['hugemem']), 'blue', bold = True)}")
        print()
    else:
        print("- CPU-hours occupied by requested memory (per queue)\n")
        print(f"    • {stylise_string('normal', bold = True)} : {stylise_string(format_number(mem_hours_task['normal']), 'blue', bold = True)}")
        print(f"    • {stylise_string('bigmem', bold = True)} : {stylise_string(format_number(mem_hours_task['bigmem']), 'blue', bold = True)}")
        print(f"    • {stylise_string('hugemem', bold = True)}: {stylise_string(format_number(mem_hours_task['hugemem']), 'blue', bold = True)}")
        print()

    # Footer
    print(stylise_string("================= End of Cost Report =======================\n", bold=True))


if __name__ == "__main__":
    args = argparse.ArgumentParser(description = 'Calculate the cost of a Slurm job on NRIS HPCs')
    args.add_argument('slurmscript_path', type = str, help = 'Path to Slurm job script')
    slurmscript_path = args.parse_args().slurmscript_path
    slurmargs = extract_slurmheader_arguments(slurmscript_path)
    parsed_slurmargs = parse_slurmargs(slurmargs)
    costs_per_queue = calculate_sbatch_jobcost_per_queue(parsed_slurmargs)
    print_cost_details(costs_per_queue, threshold = 10000)
