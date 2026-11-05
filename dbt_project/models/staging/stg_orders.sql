select
    cast(order_id as integer)           as order_id,
    cast(customer_id as integer)        as customer_id,
    cast(order_ts as timestamp)         as order_ts,
    cast(order_ts as date)              as order_date,
    lower(trim(channel))                as channel,
    lower(trim(status))                 as status,
    cast(stored_total as double)        as stored_total
from {{ source('raw_data', 'raw_orders') }}
