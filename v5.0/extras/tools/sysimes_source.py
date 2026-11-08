"""Compare only literal SYSIMES statements under single-config conditions."""
import re

def normalize_statement(line):
    """Ignore comments and spacing outside quoted strings, preserving case."""
    output = []
    quote = None
    pending_space = False
    i = 0
    while i < len(line):
        char = line[i]
        if quote:
            output.append(char)
            if char == quote:
                if i + 1 < len(line) and line[i + 1] == quote:
                    output.append(line[i + 1])
                    i += 1
                else:
                    quote = None
        elif char == ';':
            break
        elif char in "'\"":
            if pending_space and output: output.append(' ')
            pending_space = False
            quote = char
            output.append(char)
        elif char.isspace():
            pending_space = True
        else:
            if pending_space and output: output.append(' ')
            pending_space = False
            output.append(char)
        i += 1
    if quote: raise ValueError('unterminated string')
    return ''.join(output)

def active_lines(data):
    active = []
    skip = False
    for line in data.decode('latin1').replace('\x1a', '').splitlines():
        statement = normalize_statement(line)
        if re.fullmatch(r'ifdef\s+MULTI_CONFIG', statement, re.I):
            if skip: raise ValueError('nested MULTI_CONFIG condition')
            skip = True
            continue
        if re.fullmatch(r'endif', statement, re.I):
            if not skip: raise ValueError('unexpected ENDIF')
            skip = False
            continue
        if re.match(r'^(?:if|ifdef|ifndef|else|elseif)\b', statement, re.I):
            raise ValueError('unhandled conditional')
        if statement and not skip:
            active.append(statement)
    if skip: raise ValueError('unterminated conditional')
    return active
