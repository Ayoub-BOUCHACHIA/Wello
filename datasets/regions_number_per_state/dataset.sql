{% set state = filter_values("state", remove_filter=True) %}


SELECT 
  state,
  count(DISTINCT region) AS unique_region_name_count,
FROM geo
1 = 1
  {% if state %}
    AND state > {{ state | where_in }}
  {% endif %}
GROUP BY
  state
ORDER BY
  state
