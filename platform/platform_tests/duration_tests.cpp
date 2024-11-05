#include "testing/testing.hpp"

#include "platform/duration.hpp"

#include <chrono>

namespace platform
{
void AddUnit(long value, Duration::Units unit, std::string & result)
{
  if (value == 0)
    return;
  if (!result.empty())
    result += kNonBreakingSpace;
  result += std::to_string(value);
  result += kNarrowNonBreakingSpace;
  result += Duration::GetUnitsString(unit);
}

struct TestData
{
  std::chrono::days m_days;
  std::chrono::hours m_hours;
  std::chrono::minutes m_minutes;

  TestData(long days, long hours, long minutes)
    : m_days(days), m_hours(hours), m_minutes(minutes)
  {}

  long Seconds() const
  {
    return (std::chrono::duration_cast<std::chrono::seconds>(m_days) +
            std::chrono::duration_cast<std::chrono::seconds>(m_hours) +
            std::chrono::duration_cast<std::chrono::seconds>(m_minutes)).count();
  }

  std::string ToString()
  {
    std::string result;
    AddUnit(m_days.count(), Duration::Units::Days, result);
    AddUnit(m_hours.count(), Duration::Units::Hours, result);
    AddUnit(m_minutes.count(), Duration::Units::Minutes, result);
    if (result.empty())
      result = "0" + kNarrowNonBreakingSpace + Duration::GetUnitsString(Duration::Units::Minutes);
    return result;
  }
};

UNIT_TEST(Duration_AllUnits)
{
  TestData testData[] = {
    {0, 0, 0},
    {0, 0, 2},
    {0, 3, 0},
    {4, 0, 0},
    {1, 2, 3},
    {1, 0, 15},
    {0, 15, 1},
    {1, 15, 0},
    {15, 0, 10},
    {15, 15, 15},
  };
  for (TestData & data : testData)
  {
    auto const durationStr = Duration(data.Seconds()).GetString();
    TEST_EQUAL(durationStr, data.ToString(), ());
  }
}

UNIT_TEST(Duration_OneUnit)
{
  TestData testData[] = {
    {0, 0, 0},
    {0, 0, 10},
    {0, 0, 100},
    {0, 0, 1000},
  };
  for (TestData & data : testData)
  {
    auto const minutesStr = Duration(data.Seconds()).GetString({Duration::Units::Minutes});
    TEST_EQUAL(minutesStr, data.ToString(), ());
  };
  TestData testHoursData[] = {
    {0, 1, 0},
    {0, 10, 0},
    {0, 100, 0},
    {0, 1000, 0},
  };
  for (TestData & data : testHoursData)
  {
    auto const hoursStr = Duration(data.Seconds()).GetString({Duration::Units::Hours});
    TEST_EQUAL(hoursStr, data.ToString(), ());
  }
  TestData testDaysData[] = {
    {1, 0, 0},
    {10, 0, 0},
    {100, 0, 0},
    {1000, 0, 0},
  };
  for (TestData & data : testDaysData)
  {
    auto const daysStr = Duration(data.Seconds()).GetString({Duration::Units::Days});
    TEST_EQUAL(daysStr, data.ToString(), ());
  }
}
}  // namespace platform
