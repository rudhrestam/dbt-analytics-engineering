-- Data-quality mart: every check runs over the staged data and reports how
-- many records fail. This is the table a data team would alert on.
with checks as (

    select 'orders_with_no_line_items' as check_name,
           count(*) as failed_records
    from {{ ref('stg_orders') }} o
    where not exists (
        select 1 from {{ ref('stg_order_items') }} i where i.order_id = o.order_id
    )

    union all
    select 'orders_total_mismatch_vs_line_items',
           count(*)
    from (
        select o.order_id
        from {{ ref('stg_orders') }} o
        join {{ ref('stg_order_items') }} i on i.order_id = o.order_id
        group by o.order_id, o.stored_total
        having abs(o.stored_total - sum(i.line_total)) > 0.01
    ) m

    union all
    select 'non_positive_line_quantities',
           count(*)
    from {{ ref('stg_order_items') }}
    where quantity <= 0

    union all
    select 'customers_with_no_orders',
           count(*)
    from {{ ref('stg_customers') }} c
    where not exists (
        select 1 from {{ ref('stg_orders') }} o where o.customer_id = c.customer_id
    )

    union all
    select 'refunded_or_cancelled_with_revenue_lines',
           count(distinct order_id)
    from {{ ref('int_order_lines') }}
    where status in ('refunded', 'cancelled') and line_total <= 0
)
select
    check_name,
    failed_records,
    case when failed_records = 0 then 'pass' else 'review' end as check_status
from checks
order by failed_records desc
