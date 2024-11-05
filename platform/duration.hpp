#pragma once

#include "platform/localization.hpp"

#include <string>
#include <set>
#include <chrono>

namespace platform
{

class Duration
{
public:
  enum class Units
  {
    Days = 0,
    Hours = 1,
    Minutes = 2,
  };

  struct UnitsComparator
  {
    bool operator()(Units lhs, Units rhs) const
    {
      return static_cast<int>(lhs) < static_cast<int>(rhs);
    }
  };

  typedef std::set<Units, UnitsComparator> UnitsSet;

  explicit Duration(long seconds);

  static std::string GetUnitsString(Units unit);

  std::string GetString(UnitsSet units = {Units::Days, Units::Hours, Units::Minutes}) const;

private:
  std::chrono::seconds m_seconds;
};

std::string DebugPrint(Duration::Units units);

}  // namespace platform
