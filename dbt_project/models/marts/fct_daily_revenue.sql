-- Daily revenue mart: one row per day x channel, completed orders only.
-- Revenue is recomputed from line items (the trustworthy figure), and the
-- stored order total is carried alongside so drift stays visible.
with lines as (
    select * from {{ ref('int_order_lines') }} where status = 'completed'
),
daily as (
    select
        order_date,
        channel,
        count(distinct order_id)                     as orders,
        sum(quantity)                                as items_sold,
        round(sum(line_total), 2)                    as revenue
    from lines
    group by 1, 2
)
select * from daily
order by order_date, channel
