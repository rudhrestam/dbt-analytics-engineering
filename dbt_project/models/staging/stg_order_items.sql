select
    cast(item_id as integer)            as item_id,
    cast(order_id as integer)           as order_id,
    cast(product_id as integer)         as product_id,
    cast(quantity as integer)           as quantity,
    cast(line_total as double)          as line_total
from {{ source('raw_data', 'raw_order_items') }}
