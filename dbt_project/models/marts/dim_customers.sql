-- Customer dimension with lifetime behaviour summary.
with orders as (
    select * from {{ ref('stg_orders') }} where status = 'completed'
),
lines as (
    select * from {{ ref('int_order_lines') }} where status = 'completed'
),
agg as (
    select
        o.customer_id,
        count(distinct o.order_id)                   as lifetime_orders,
        round(sum(l.line_total), 2)                  as lifetime_revenue,
        min(o.order_date)                            as first_order_date,
        max(o.order_date)                            as last_order_date
    from orders o
    left join lines l on l.order_id = o.order_id
    group by 1
)
select
    c.customer_id,
    c.full_name,
    c.email,
    c.signup_date,
    c.home_store,
    coalesce(a.lifetime_orders, 0)                   as lifetime_orders,
    coalesce(a.lifetime_revenue, 0)                  as lifetime_revenue,
    a.first_order_date,
    a.last_order_date,
    case
        when coalesce(a.lifetime_orders, 0) >= 10 then 'regular'
        when coalesce(a.lifetime_orders, 0) >= 4  then 'occasional'
        when coalesce(a.lifetime_orders, 0) >= 1  then 'one_time'
        else 'never_ordered'
    end                                              as customer_segment
from {{ ref('stg_customers') }} c
left join agg a on a.customer_id = c.customer_id
