select
    cast(product_id as integer)         as product_id,
    trim(product_name)                  as product_name,
    lower(trim(category))               as category,
    cast(unit_price as double)          as unit_price
from {{ source('raw_data', 'raw_products') }}
