{{
    config(materialized='table')
}}

with date_spine as (
    select
        generate_series(
            '2022-01-01'::date,
            '2025-12-31'::date,
            '1 day'::interval
        )::date as date_day
),

nigeria_holidays as (
    select unnest(array[
        '2024-01-01','2024-02-26','2024-04-01','2024-04-02',
        '2024-04-10','2024-05-01','2024-05-27','2024-06-12',
        '2024-06-17','2024-10-01','2024-12-25','2024-12-26',
        '2023-01-01','2023-02-18','2023-04-07','2023-04-08',
        '2023-04-10','2023-05-01','2023-05-29','2023-06-12',
        '2023-06-28','2023-09-27','2023-10-01','2023-12-25','2023-12-26',
        '2022-01-01','2022-01-03','2022-04-15','2022-04-18',
        '2022-05-01','2022-05-03','2022-05-30','2022-06-13',
        '2022-07-10','2022-10-01','2022-12-25','2022-12-26'
    ]::date[]) as holiday_date
),

final as (
    select
        to_char(d.date_day, 'YYYYMMDD')::integer    as date_key,
        d.date_day                                   as full_date,
        extract(year  from d.date_day)::integer      as year,
        extract(quarter from d.date_day)::integer    as quarter,
        extract(month from d.date_day)::integer      as month,
        to_char(d.date_day, 'Month')                 as month_name,
        extract(week  from d.date_day)::integer      as week_of_year,
        extract(day   from d.date_day)::integer      as day_of_month,
        extract(dow   from d.date_day)::integer      as day_of_week,
        to_char(d.date_day, 'Day')                   as day_name,
        case when extract(dow from d.date_day) in (0,6)
             then true else false end                as is_weekend,
        case when h.holiday_date is not null
             then true else false end                as is_public_holiday,
        extract(year  from d.date_day) || '-Q' ||
            extract(quarter from d.date_day)         as year_quarter,
        to_char(d.date_day, 'YYYY-MM')               as year_month
    from date_spine d
    left join nigeria_holidays h on h.holiday_date = d.date_day
)

select * from final
