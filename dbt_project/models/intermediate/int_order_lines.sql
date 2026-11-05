-- One row per order line, enriched with order and product context.
select
    i.item_id,
    i.order_id,
    o.customer_id,
    o.order_date,
    o.channel,
    o.status,
    i.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    i.quantity,
    i.line_total
from {{ ref('stg_order_items') }} i
join {{ ref('stg_orders') }} o   on o.order_id = i.order_id
join {{ ref('stg_products') }} p on p.product_id = i.product_id
