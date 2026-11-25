-- =============================================================================
-- Egypt Energy & Renewables Lakehouse — Executive Analytical Queries
-- Target Schema: workspace.gold (Databricks Unity Catalog)
-- =============================================================================

-- 1. Total Installed Renewable Capacity Growth Over Time (IRENA)
WITH yearly_capacity AS (
    SELECT
        y.year,
        ROUND(SUM(f.capacity_mw), 2) AS total_renewable_mw
    FROM workspace.gold.fact_irena_capacity f
    JOIN workspace.gold.dim_year y
        ON f.year_key = y.year_key
    GROUP BY y.year
)
SELECT
    year,
    total_renewable_mw,
    ROUND(
        (total_renewable_mw - LAG(total_renewable_mw) OVER (ORDER BY year))
        / NULLIF(LAG(total_renewable_mw) OVER (ORDER BY year), 0) * 100,
        2
    ) AS yoy_growth_pct
FROM yearly_capacity
ORDER BY year DESC;


-- 2. Renewable Capacity Breakdown by Technology (Latest Available Year)
WITH latest_year AS (
    SELECT MAX(year) AS max_year
    FROM workspace.gold.dim_year
)
SELECT
    t.technology_name,
    ROUND(SUM(f.capacity_mw), 2) AS installed_mw,
    ROUND(
        SUM(f.capacity_mw) * 100.0 / SUM(SUM(f.capacity_mw)) OVER (),
        2
    ) AS share_pct
FROM workspace.gold.fact_irena_capacity f
JOIN workspace.gold.dim_year y
    ON f.year_key = y.year_key
JOIN workspace.gold.dim_technology t
    ON f.technology_key = t.technology_key
WHERE y.year = (SELECT max_year FROM latest_year)
GROUP BY t.technology_name
ORDER BY installed_mw DESC;


-- 3. Annual Energy Mix Summary (EIA)
SELECT
    y.year,
    s.energy_source_name,
    ROUND(SUM(f.value), 2) AS total_energy_value
FROM workspace.gold.fact_energy_mix f
JOIN workspace.gold.dim_year y
    ON f.year_key = y.year_key
JOIN workspace.gold.dim_energy_source s
    ON f.energy_source_key = s.energy_source_key
GROUP BY y.year, s.energy_source_name
ORDER BY y.year DESC, total_energy_value DESC;


-- 4. Executive Annual KPI Snapshot (Pre-aggregated Gold View)
SELECT *
FROM workspace.gold.vw_egypt_energy_annual_summary
ORDER BY year DESC
LIMIT 15;