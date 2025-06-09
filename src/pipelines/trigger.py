from dataclasses import dataclass

from pipelines import port


def standard_to_quartz(standard_cron):
    """
    Converts a standard cron expression (5 fields) to a Quartz cron expression (7 fields).
    """
    fields = standard_cron.split()
    if len(fields) != 5:
        raise ValueError("Invalid standard cron format. Expected 5 fields.")
    minute, hour, day, month, weekday = fields
    # Convert '*' to '?' in either the day or weekday field (Quartz requires one of them to be '?')
    if day == "*":
        day = "?"
    elif weekday == "*":
        weekday = "?"
    # Add "0" for the seconds field and "*" for the optional year field
    quartz_cron = f"0 {minute} {hour} {day} {month} {weekday} *"
    return quartz_cron


def quartz_to_standard(quartz_cron):
    """
    Converts a Quartz cron expression (6-7 fields) to a standard cron expression (5 fields).
    """
    fields = quartz_cron.split()
    if len(fields) not in [6, 7]:
        raise ValueError("Invalid Quartz cron format. Expected 6 or 7 fields.")
    # Remove the seconds field and optional year field
    _, minute, hour, day, month, weekday, *_ = fields
    # Convert '?' to '*' in either the day or weekday field
    if day == "?":
        day = "*"
    elif weekday == "?":
        weekday = "*"
    standard_cron = f"{minute} {hour} {day} {month} {weekday}"
    return standard_cron


@dataclass
class Trigger(port.Port): ...


@dataclass
class CronTrigger(Trigger):
    schedule: str
    start_date: str
