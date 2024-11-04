#include "map/elevation_info.hpp"

#include "geometry/mercator.hpp"

ElevationInfo::ElevationInfo(kml::MultiGeometry const & geometry)
{
  double distance = 0.0;
  
  // Concatenate all segments.
  for (size_t i = 0; i < geometry.m_lines.size(); ++i)
  {
    auto const & points = geometry.m_lines[i];
    if (points.empty())
      return;

    double segmentStartDistance = 0.0;
    if (i == 0)
    {
      auto const & baseAltitude = points[i].GetAltitude();
      m_minAltitude = baseAltitude;
      m_maxAltitude = baseAltitude;
    }
    else
      segmentStartDistance = m_points.back().m_distance;

    m_segmentDistances.emplace_back(segmentStartDistance);
    m_points.emplace_back(points[i], segmentStartDistance);

    for (size_t j = 1; j < points.size(); ++j)
    {
      distance += mercator::DistanceOnEarth(points[j - 1].GetPoint(), points[j].GetPoint());
      m_points.emplace_back(points[j], distance);

      auto const & previousPointAltitude = points[j - 1].GetAltitude();
      auto const & currentPointAltitude = points[j].GetAltitude();
      auto const deltaAltitude = currentPointAltitude - previousPointAltitude;
      if (deltaAltitude > 0)
        m_ascent += deltaAltitude;
      else
        m_descent -= deltaAltitude;

      if (currentPointAltitude < m_minAltitude)
        m_minAltitude = currentPointAltitude;
      if (currentPointAltitude > m_maxAltitude)
        m_maxAltitude = currentPointAltitude;
    }
  }
  /// @todo(KK) Implement difficulty calculation.
  m_difficulty = Difficulty::Unknown;
}
