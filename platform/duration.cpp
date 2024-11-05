#include "duration.hpp"

namespace platform
{
namespace
{
long SecondsToUnits(std::chrono::seconds duration, Duration::Units unit)
{
  switch (unit)
  {
    case Duration::Units::Days: return std::chrono::duration_cast<std::chrono::days>(duration).count();
    case Duration::Units::Hours: return std::chrono::duration_cast<std::chrono::hours>(duration).count();
    case Duration::Units::Minutes: return std::chrono::duration_cast<std::chrono::minutes>(duration).count();
    default: UNREACHABLE();
  }
}

std::chrono::seconds UnitsToSeconds(long value, Duration::Units unit)
{
  switch (unit)
  {
    case Duration::Units::Days: return std::chrono::days(value);
    case Duration::Units::Hours: return std::chrono::hours(value);
    case Duration::Units::Minutes: return std::chrono::minutes(value);
    default: UNREACHABLE();
  }
}
}

Duration::Duration(long seconds) : m_seconds(seconds) {
  ASSERT(seconds >= 0, ());
}

std::string Duration::GetString(UnitsSet units) const
{
  ASSERT(!units.empty(), ());
  if (m_seconds.count() == 0)
    return "0" + kNarrowNonBreakingSpace + GetUnitsString(Units::Minutes);

  std::string formattedTime;
  std::chrono::seconds remainingSeconds = m_seconds;
  for (auto unit : units)
  {
    long unitsCount = SecondsToUnits(remainingSeconds, unit);
    if (unitsCount > 0)
    {
      if (!formattedTime.empty())
        formattedTime += kNonBreakingSpace;
      formattedTime += std::to_string(unitsCount) + kNarrowNonBreakingSpace + GetUnitsString(unit);
      remainingSeconds -= UnitsToSeconds(unitsCount, unit);
    }
  }
  return formattedTime;
}

std::string Duration::GetUnitsString(Units unit)
{
  switch (unit)
  {
    case Units::Minutes: return GetLocalizedString("minute");
    case Units::Hours: return GetLocalizedString("hour");
    case Units::Days: return GetLocalizedString("day");
    default: UNREACHABLE();
  }
}
}
