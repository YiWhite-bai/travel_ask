CREATE TABLE areas (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    area_code VARCHAR(20) NOT NULL,
    area_name VARCHAR(100) NOT NULL,
    area_full_name VARCHAR(255) NULL,
    parent_id BIGINT UNSIGNED NULL,
    `level` TINYINT UNSIGNED NOT NULL COMMENT '地区层级枚举：1=省级/直辖市级，2=地市级，3=区县级',
    postal_code VARCHAR(10) NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_areas_code (area_code),
    CONSTRAINT fk_areas_parent FOREIGN KEY (parent_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '地区表';

CREATE TABLE currencies (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    currency_code VARCHAR(10) NOT NULL,
    currency_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    precision_scale TINYINT UNSIGNED NOT NULL DEFAULT 2,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_currencies_code (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '币种表';

CREATE TABLE channels (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    channel_code VARCHAR(20) NOT NULL,
    channel_name VARCHAR(50) NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_channels_code (channel_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '渠道表';

CREATE TABLE transport_hubs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hub_code VARCHAR(20) NOT NULL,
    hub_name VARCHAR(120) NOT NULL,
    hub_type_code VARCHAR(30) NOT NULL COMMENT '枢纽类型枚举：airport=机场，railway_station=火车站，bus_station=汽车站',
    city_area_id BIGINT UNSIGNED NOT NULL,
    address VARCHAR(255) NULL,
    latitude DECIMAL(10, 6) NULL,
    longitude DECIMAL(10, 6) NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_transport_hubs_code (hub_code),
    CONSTRAINT fk_transport_hubs_city FOREIGN KEY (city_area_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '交通枢纽表';

CREATE TABLE suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    supplier_code VARCHAR(30) NOT NULL,
    supplier_name VARCHAR(200) NOT NULL,
    supplier_type_code VARCHAR(30) NOT NULL COMMENT '供应商类型枚举：hotel=酒店，scenic=景点，flight=机票，train=火车票，bus=汽车票，transfer=接送',
    area_id BIGINT UNSIGNED NOT NULL,
    contact_name VARCHAR(100) NULL,
    contact_phone VARCHAR(30) NULL,
    contact_email VARCHAR(120) NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_suppliers_code (supplier_code),
    CONSTRAINT fk_suppliers_area FOREIGN KEY (area_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '供应商表';

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nickname VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(500) NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(120) NOT NULL,
    gender_code VARCHAR(20) NOT NULL COMMENT '性别枚举：male=男，female=女，unknown=未知',
    birth_date DATE NULL,
    register_area_id BIGINT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'normal' COMMENT '用户状态枚举：normal=正常，vip=VIP用户，inactive=已停用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_users_phone (phone),
    UNIQUE KEY uk_users_email (email),
    CONSTRAINT fk_users_area FOREIGN KEY (register_area_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户表';

CREATE TABLE user_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    real_name VARCHAR(100) NOT NULL,
    identity_no VARCHAR(64) NOT NULL,
    identity_type_code VARCHAR(30) NOT NULL COMMENT '证件类型枚举：id_card=居民身份证，passport=护照',
    residence_city_name VARCHAR(255) NULL,
    occupation VARCHAR(100) NULL,
    preference_payload JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_profiles_user (user_id),
    CONSTRAINT fk_user_profiles_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户资料表';

CREATE TABLE travelers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    traveler_name VARCHAR(100) NOT NULL,
    identity_no VARCHAR(64) NOT NULL,
    identity_type_code VARCHAR(30) NOT NULL COMMENT '证件类型枚举：id_card=居民身份证，passport=护照',
    gender_code VARCHAR(20) NOT NULL COMMENT '性别枚举：male=男，female=女',
    birth_date DATE NULL,
    phone VARCHAR(30) NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_travelers_user_identity (user_id, identity_type_code, identity_no),
    KEY idx_travelers_id_user (id, user_id),
    CONSTRAINT fk_travelers_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '常用出行人';

CREATE TABLE member_accounts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    member_level_code VARCHAR(30) NOT NULL COMMENT '会员等级枚举：normal=普通会员，silver=银卡会员，gold=金卡会员',
    points_balance INT NOT NULL DEFAULT 0,
    total_points INT NOT NULL DEFAULT 0,
    growth_value INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_member_accounts_user (user_id),
    CONSTRAINT fk_member_accounts_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '会员账户';

CREATE TABLE member_point_ledger (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    ledger_type_code VARCHAR(30) NOT NULL COMMENT '积分流水类型枚举：signup_bonus=注册奖励，order_earn=订单获积分，order_earn_revoke=退款撤销获积分，point_redeem=积分抵扣，expire=过期，admin_adjust=人工调整',
    points_delta INT NOT NULL,
    balance_after INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_member_point_ledger_id_user (id, user_id),
    KEY idx_member_point_ledger_user_id (user_id, id),
    CONSTRAINT fk_member_point_ledger_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '积分流水';

CREATE TABLE hotels (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hotel_code VARCHAR(30) NOT NULL,
    hotel_name VARCHAR(200) NOT NULL,
    hotel_type_code VARCHAR(30) NOT NULL COMMENT '酒店类型枚举：luxury=豪华型，business=商务型，resort=度假型，boutique=精品型',
    star_rating_code VARCHAR(10) NOT NULL COMMENT '星级枚举：3=三星，4=四星，5=五星',
    area_id BIGINT UNSIGNED NOT NULL,
    address VARCHAR(255) NULL,
    latitude DECIMAL(10, 6) NULL,
    longitude DECIMAL(10, 6) NULL,
    summary TEXT NULL,
    facility_payload JSON NULL,
    check_in_time TIME NULL,
    check_out_time TIME NULL,
    contact_phone VARCHAR(30) NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_hotels_code (hotel_code),
    CONSTRAINT fk_hotels_area FOREIGN KEY (area_id) REFERENCES areas (id),
    CONSTRAINT fk_hotels_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '酒店表';

CREATE TABLE hotel_room_types (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hotel_id BIGINT UNSIGNED NOT NULL,
    room_type_code VARCHAR(30) NOT NULL,
    room_type_name VARCHAR(120) NOT NULL,
    room_type_category_code VARCHAR(30) NOT NULL COMMENT '房型分类枚举：double=大床房，twin=双床房，suite=套房，family=家庭房',
    area_size INT UNSIGNED NULL,
    max_guests INT UNSIGNED NOT NULL,
    amenity_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_hotel_room_type_code (room_type_code),
    CONSTRAINT fk_hotel_room_types_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '酒店房型表';

CREATE TABLE hotel_booking_rules (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hotel_id BIGINT UNSIGNED NOT NULL,
    hold_until_time TIME NULL,
    min_stay_nights INT UNSIGNED NOT NULL DEFAULT 1,
    max_room_count INT UNSIGNED NOT NULL DEFAULT 1,
    rule_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_hotel_booking_rules_hotel (hotel_id),
    CONSTRAINT fk_hotel_booking_rules_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '酒店预订规则';

CREATE TABLE hotel_room_daily (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_type_id BIGINT UNSIGNED NOT NULL,
    business_date DATE NOT NULL,
    total_inventory INT UNSIGNED NOT NULL,
    available_inventory INT UNSIGNED NOT NULL,
    reserved_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    sold_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    currency_code VARCHAR(10) NOT NULL,
    sale_price_amount DECIMAL(12, 2) NOT NULL,
    settlement_price_amount DECIMAL(12, 2) NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_hotel_room_daily (room_type_id, business_date),
    CONSTRAINT fk_hotel_room_daily_room FOREIGN KEY (room_type_id) REFERENCES hotel_room_types (id),
    CONSTRAINT fk_hotel_room_daily_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '酒店房态房价日历';

CREATE TABLE scenic_spots (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    scenic_code VARCHAR(30) NOT NULL,
    scenic_name VARCHAR(200) NOT NULL,
    scenic_type_code VARCHAR(30) NOT NULL COMMENT '景点类型枚举：theme_park=主题公园，museum=博物馆，mountain=山地景区，heritage=文化遗产，wetland=湿地公园，beach=海滨景区，snow=冰雪景区，forest=森林公园，waterfall=瀑布溪流，cultural_square=文化广场，ancient_town=古镇古街，religious=宗教场所，theme_water=水上乐园，zoo=动物园，botanical_garden=植物园，industrial_tourism=工业旅游，red_tourism=红色旅游，ecological=生态景区',
    rating_code VARCHAR(10) NOT NULL COMMENT '景区等级枚举：5A=5A级，4A=4A级，3A=3A级',
    area_id BIGINT UNSIGNED NOT NULL,
    address VARCHAR(255) NULL,
    latitude DECIMAL(10, 6) NULL,
    longitude DECIMAL(10, 6) NULL,
    summary TEXT NULL,
    tag_payload JSON NULL,
    open_time TIME NULL,
    close_time TIME NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_scenic_spots_code (scenic_code),
    CONSTRAINT fk_scenic_spots_area FOREIGN KEY (area_id) REFERENCES areas (id),
    CONSTRAINT fk_scenic_spots_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '景点表';

CREATE TABLE scenic_ticket_types (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    scenic_spot_id BIGINT UNSIGNED NOT NULL,
    ticket_type_code VARCHAR(30) NOT NULL,
    ticket_type_name VARCHAR(120) NOT NULL,
    ticket_category_code VARCHAR(30) NOT NULL COMMENT '票种分类枚举：adult=成人票，student=学生票，family=家庭票，night=夜场票',
    benefit_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_scenic_ticket_type_code (ticket_type_code),
    CONSTRAINT fk_scenic_ticket_types_spot FOREIGN KEY (scenic_spot_id) REFERENCES scenic_spots (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '景点票种表';

CREATE TABLE scenic_booking_rules (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    scenic_spot_id BIGINT UNSIGNED NOT NULL,
    latest_booking_time TIME NULL,
    rule_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_scenic_booking_rules_spot (scenic_spot_id),
    CONSTRAINT fk_scenic_booking_rules_spot FOREIGN KEY (scenic_spot_id) REFERENCES scenic_spots (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '景点预订规则';

CREATE TABLE scenic_ticket_daily (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_type_id BIGINT UNSIGNED NOT NULL,
    business_date DATE NOT NULL,
    total_inventory INT UNSIGNED NOT NULL,
    available_inventory INT UNSIGNED NOT NULL,
    reserved_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    sold_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    currency_code VARCHAR(10) NOT NULL,
    sale_price_amount DECIMAL(12, 2) NOT NULL,
    settlement_price_amount DECIMAL(12, 2) NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_scenic_ticket_daily (ticket_type_id, business_date),
    CONSTRAINT fk_scenic_ticket_daily_ticket FOREIGN KEY (ticket_type_id) REFERENCES scenic_ticket_types (id),
    CONSTRAINT fk_scenic_ticket_daily_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '景点票日历';

CREATE TABLE flight_routes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_code VARCHAR(30) NOT NULL,
    flight_no VARCHAR(30) NOT NULL,
    airline_code VARCHAR(10) NOT NULL COMMENT '航司枚举：MU=东方航空，CA=中国国航，CZ=南方航空，HU=海南航空，HO=吉祥航空，3U=四川航空，FM=上海航空，9C=春秋航空，BK=奥凯航空，KN=中国联航，SC=山东航空，TV=西藏航空，EU=成都航空，G5=华夏航空，JR=天津航空，NS=河北航空，JD=首都航空，ZH=深圳航空，PN=西部航空，CO=长龙航空',
    supplier_id BIGINT UNSIGNED NOT NULL,
    departure_hub_id BIGINT UNSIGNED NOT NULL,
    arrival_hub_id BIGINT UNSIGNED NOT NULL,
    departure_area_id BIGINT UNSIGNED NOT NULL,
    arrival_area_id BIGINT UNSIGNED NOT NULL,
    duration_minutes INT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_flight_routes_code (route_code),
    CONSTRAINT fk_flight_routes_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_flight_routes_departure_hub FOREIGN KEY (departure_hub_id) REFERENCES transport_hubs (id),
    CONSTRAINT fk_flight_routes_arrival_hub FOREIGN KEY (arrival_hub_id) REFERENCES transport_hubs (id),
    CONSTRAINT fk_flight_routes_departure_area FOREIGN KEY (departure_area_id) REFERENCES areas (id),
    CONSTRAINT fk_flight_routes_arrival_area FOREIGN KEY (arrival_area_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '航线表';

CREATE TABLE flight_departures (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    flight_route_id BIGINT UNSIGNED NOT NULL,
    departure_instance_code VARCHAR(50) NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    rule_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'scheduled' COMMENT '班次状态枚举：scheduled=已排班，cancelled=已取消，done=已完成',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_flight_departures_code (departure_instance_code),
    CONSTRAINT fk_flight_departures_route FOREIGN KEY (flight_route_id) REFERENCES flight_routes (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '航班实例表';

CREATE TABLE flight_cabin_inventory (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    flight_departure_id BIGINT UNSIGNED NOT NULL,
    cabin_class_code VARCHAR(30) NOT NULL COMMENT '舱位等级枚举：economy=经济舱，business=商务舱',
    currency_code VARCHAR(10) NOT NULL,
    sale_price_amount DECIMAL(12, 2) NOT NULL,
    settlement_price_amount DECIMAL(12, 2) NOT NULL,
    total_inventory INT UNSIGNED NOT NULL,
    available_inventory INT UNSIGNED NOT NULL,
    reserved_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    sold_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_flight_cabin_inventory (flight_departure_id, cabin_class_code),
    CONSTRAINT fk_flight_cabin_inventory_departure FOREIGN KEY (flight_departure_id) REFERENCES flight_departures (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '航班舱位库存';

CREATE TABLE train_routes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_code VARCHAR(30) NOT NULL,
    train_no VARCHAR(30) NOT NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    departure_hub_id BIGINT UNSIGNED NOT NULL,
    arrival_hub_id BIGINT UNSIGNED NOT NULL,
    departure_area_id BIGINT UNSIGNED NOT NULL,
    arrival_area_id BIGINT UNSIGNED NOT NULL,
    duration_minutes INT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_train_routes_code (route_code),
    CONSTRAINT fk_train_routes_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_train_routes_departure_hub FOREIGN KEY (departure_hub_id) REFERENCES transport_hubs (id),
    CONSTRAINT fk_train_routes_arrival_hub FOREIGN KEY (arrival_hub_id) REFERENCES transport_hubs (id),
    CONSTRAINT fk_train_routes_departure_area FOREIGN KEY (departure_area_id) REFERENCES areas (id),
    CONSTRAINT fk_train_routes_arrival_area FOREIGN KEY (arrival_area_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '火车线路表';

CREATE TABLE train_departures (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    train_route_id BIGINT UNSIGNED NOT NULL,
    departure_instance_code VARCHAR(50) NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'scheduled' COMMENT '班次状态枚举：scheduled=已排班，cancelled=已取消，done=已完成',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_train_departures_code (departure_instance_code),
    CONSTRAINT fk_train_departures_route FOREIGN KEY (train_route_id) REFERENCES train_routes (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '火车班次实例表';

CREATE TABLE train_seat_inventory (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    train_departure_id BIGINT UNSIGNED NOT NULL,
    seat_class_code VARCHAR(30) NOT NULL COMMENT '席位等级枚举：second_class=二等座，first_class=一等座，business=商务座',
    currency_code VARCHAR(10) NOT NULL,
    sale_price_amount DECIMAL(12, 2) NOT NULL,
    settlement_price_amount DECIMAL(12, 2) NOT NULL,
    total_inventory INT UNSIGNED NOT NULL,
    available_inventory INT UNSIGNED NOT NULL,
    reserved_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    sold_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_train_seat_inventory (train_departure_id, seat_class_code),
    CONSTRAINT fk_train_seat_inventory_departure FOREIGN KEY (train_departure_id) REFERENCES train_departures (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '火车席位库存';

CREATE TABLE bus_routes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_code VARCHAR(30) NOT NULL,
    route_name VARCHAR(100) NOT NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    departure_hub_id BIGINT UNSIGNED NOT NULL,
    arrival_hub_id BIGINT UNSIGNED NOT NULL,
    departure_area_id BIGINT UNSIGNED NOT NULL,
    arrival_area_id BIGINT UNSIGNED NOT NULL,
    duration_minutes INT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_bus_routes_code (route_code),
    CONSTRAINT fk_bus_routes_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_bus_routes_departure_hub FOREIGN KEY (departure_hub_id) REFERENCES transport_hubs (id),
    CONSTRAINT fk_bus_routes_arrival_hub FOREIGN KEY (arrival_hub_id) REFERENCES transport_hubs (id),
    CONSTRAINT fk_bus_routes_departure_area FOREIGN KEY (departure_area_id) REFERENCES areas (id),
    CONSTRAINT fk_bus_routes_arrival_area FOREIGN KEY (arrival_area_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '汽车线路表';

CREATE TABLE bus_departures (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bus_route_id BIGINT UNSIGNED NOT NULL,
    departure_instance_code VARCHAR(50) NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'scheduled' COMMENT '班次状态枚举：scheduled=已排班，cancelled=已取消，done=已完成',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_bus_departures_code (departure_instance_code),
    CONSTRAINT fk_bus_departures_route FOREIGN KEY (bus_route_id) REFERENCES bus_routes (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '汽车班次实例表';

CREATE TABLE bus_seat_inventory (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bus_departure_id BIGINT UNSIGNED NOT NULL,
    seat_class_code VARCHAR(30) NOT NULL COMMENT '席位等级枚举：coach=大巴',
    currency_code VARCHAR(10) NOT NULL,
    sale_price_amount DECIMAL(12, 2) NOT NULL,
    settlement_price_amount DECIMAL(12, 2) NOT NULL,
    total_inventory INT UNSIGNED NOT NULL,
    available_inventory INT UNSIGNED NOT NULL,
    reserved_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    sold_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_bus_seat_inventory (bus_departure_id, seat_class_code),
    CONSTRAINT fk_bus_seat_inventory_departure FOREIGN KEY (bus_departure_id) REFERENCES bus_departures (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '汽车席位库存';

CREATE TABLE transfer_services (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_code VARCHAR(30) NOT NULL,
    service_name VARCHAR(200) NOT NULL,
    service_type_code VARCHAR(30) NOT NULL COMMENT '服务类型枚举：airport_pickup=机场接机，airport_dropoff=机场送机，charter_daily=包车一日游，station_transfer=车站接送',
    area_id BIGINT UNSIGNED NOT NULL,
    vehicle_type_code VARCHAR(30) NOT NULL COMMENT '车型枚举：economy=经济型，comfort=舒适型，business=商务型，van=商务车',
    passenger_capacity INT UNSIGNED NOT NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_transfer_services_code (service_code),
    CONSTRAINT fk_transfer_services_area FOREIGN KEY (area_id) REFERENCES areas (id),
    CONSTRAINT fk_transfer_services_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '接送服务表';

CREATE TABLE transfer_service_area_rules (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transfer_service_id BIGINT UNSIGNED NOT NULL,
    pickup_area_id BIGINT UNSIGNED NOT NULL,
    dropoff_area_id BIGINT UNSIGNED NOT NULL,
    price_amount DECIMAL(12, 2) NOT NULL,
    min_price_amount DECIMAL(12, 2) NOT NULL,
    rule_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_transfer_service_area_rules (transfer_service_id, pickup_area_id, dropoff_area_id),
    CONSTRAINT fk_transfer_service_area_rules_service FOREIGN KEY (transfer_service_id) REFERENCES transfer_services (id),
    CONSTRAINT fk_transfer_service_area_rules_pickup FOREIGN KEY (pickup_area_id) REFERENCES areas (id),
    CONSTRAINT fk_transfer_service_area_rules_dropoff FOREIGN KEY (dropoff_area_id) REFERENCES areas (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '接送服务区域规则';

CREATE TABLE transfer_capacity_calendar (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transfer_service_id BIGINT UNSIGNED NOT NULL,
    business_date DATE NOT NULL,
    total_inventory INT UNSIGNED NOT NULL,
    available_inventory INT UNSIGNED NOT NULL,
    reserved_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    sold_inventory INT UNSIGNED NOT NULL DEFAULT 0,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_transfer_capacity_calendar (transfer_service_id, business_date),
    CONSTRAINT fk_transfer_capacity_service FOREIGN KEY (transfer_service_id) REFERENCES transfer_services (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '接送服务容量日历';

CREATE TABLE coupon_templates (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_code VARCHAR(30) NOT NULL,
    template_name VARCHAR(120) NOT NULL,
    coupon_type_code VARCHAR(30) NOT NULL COMMENT '券类型枚举：HOTEL_ROOM_CASH=酒店满减券，HOTEL_ROOM_DISCOUNT=酒店折扣券，SCENIC_TICKET_CASH=景点满减券，SCENIC_TICKET_DISCOUNT=景点折扣券，FLIGHT_CABIN_CASH=机票满减券，FLIGHT_CABIN_DISCOUNT=机票折扣券，TRAIN_SEAT_CASH=火车票满减券，TRAIN_SEAT_DISCOUNT=火车票折扣券，BUS_SEAT_CASH=汽车票满减券，BUS_SEAT_DISCOUNT=汽车票折扣券，TRANSFER_SERVICE_CASH=接送满减券，TRANSFER_SERVICE_DISCOUNT=接送折扣券',
    applicable_product_type VARCHAR(30) NULL COMMENT '适用商品类型枚举：hotel_room=酒店房型，scenic_ticket=景点票种，flight_cabin=航班舱位，train_seat=火车席位，bus_seat=汽车席位，transfer_service=接送服务',
    applicable_supplier_id BIGINT UNSIGNED NULL,
    currency_code VARCHAR(10) NOT NULL,
    min_spend_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    max_discount_amount DECIMAL(12, 2) NULL,
    valid_from DATETIME NOT NULL,
    valid_until DATETIME NOT NULL,
    total_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    per_user_limit INT UNSIGNED NOT NULL DEFAULT 1,
    rule_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_coupon_templates_code (template_code),
    KEY idx_coupon_templates_id_product (id, applicable_product_type),
    CONSTRAINT fk_coupon_templates_supplier FOREIGN KEY (applicable_supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_coupon_templates_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '优惠券模板';

CREATE TABLE user_coupons (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    coupon_code VARCHAR(50) NOT NULL,
    currency_code VARCHAR(10) NOT NULL,
    min_spend_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    max_discount_amount DECIMAL(12, 2) NULL,
    valid_from DATETIME NOT NULL,
    valid_until DATETIME NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'available' COMMENT '优惠券状态枚举：available=可用，used=已使用，expired=已过期',
    used_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_coupons_code (coupon_code),
    KEY idx_user_coupons_id_user (id, user_id),
    KEY idx_user_coupons_id_template (id, template_id),
    CONSTRAINT fk_user_coupons_template FOREIGN KEY (template_id) REFERENCES coupon_templates (id),
    CONSTRAINT fk_user_coupons_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_user_coupons_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户优惠券';

CREATE TABLE promotions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    promotion_code VARCHAR(30) NOT NULL,
    promotion_name VARCHAR(120) NOT NULL,
    promotion_type_code VARCHAR(30) NOT NULL COMMENT '活动类型枚举：direct_discount=直接折扣，min_spend_discount=满减，flashsale=秒杀，bundling=套餐',
    currency_code VARCHAR(10) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    config_payload JSON NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '活动状态枚举：active=有效，inactive=无效，paused=暂停，finished=已结束',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_promotions_code (promotion_code),
    CONSTRAINT fk_promotions_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '促销活动';

CREATE TABLE promotion_rules (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    promotion_id BIGINT UNSIGNED NOT NULL,
    rule_name VARCHAR(120) NOT NULL,
    trigger_type_code VARCHAR(30) NOT NULL COMMENT '触发类型枚举：min_spend=满额触发，first_order=首单触发，time_window=时段触发，product_count=数量触发',
    trigger_payload JSON NULL,
    benefit_type_code VARCHAR(30) NOT NULL COMMENT '优惠类型枚举：discount_amount=固定优惠金额，discount_rate=折扣率，gift_item=赠品',
    benefit_payload JSON NULL,
    sort_order INT UNSIGNED NOT NULL DEFAULT 1,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_promotion_rules_promotion FOREIGN KEY (promotion_id) REFERENCES promotions (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '促销规则';

CREATE TABLE promotion_bindings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    promotion_id BIGINT UNSIGNED NOT NULL,
    product_type_code VARCHAR(30) NOT NULL COMMENT '商品类型枚举：hotel_room=酒店房型，scenic_ticket=景点票种，flight_cabin=航班舱位，train_seat=火车席位，bus_seat=汽车席位，transfer_service=接送服务',
    target_id BIGINT UNSIGNED NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态枚举：active=有效，inactive=无效',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_promotion_bindings (promotion_id, product_type_code, target_id),
    KEY idx_promotion_bindings_id_type (id, product_type_code),
    KEY idx_promotion_bindings_id_promotion (id, promotion_id),
    CONSTRAINT fk_promotion_bindings_promotion FOREIGN KEY (promotion_id) REFERENCES promotions (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '促销绑定';

CREATE TABLE orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(50) NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    order_type_code VARCHAR(30) NOT NULL COMMENT '订单类型枚举：hotel_room=酒店订单，scenic_ticket=景点门票订单，flight_cabin=机票订单，train_seat=火车票订单，bus_seat=汽车票订单，transfer_service=接送服务订单',
    status_code VARCHAR(20) NOT NULL COMMENT '订单状态枚举：pending_payment=待支付，cancelled=已取消，paid=已支付，in_progress=进行中，finished=已结束',
    currency_code VARCHAR(10) NOT NULL,
    goods_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    marketing_discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    coupon_discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    point_discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payable_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    paid_amount DECIMAL(12, 2) NULL,
    refunded_amount DECIMAL(12, 2) NULL,
    settlement_amount DECIMAL(12, 2) NULL,
    source_channel_code VARCHAR(20) NOT NULL,
    cancel_reason VARCHAR(255) NULL,
    paid_at DATETIME NULL,
    finalized_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_orders_no (order_no),
    KEY idx_orders_id_user (id, user_id),
    KEY idx_orders_id_type (id, order_type_code),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_orders_channel FOREIGN KEY (source_channel_code) REFERENCES channels (channel_code),
    CONSTRAINT fk_orders_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '订单主表';

CREATE TABLE order_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    traveler_id BIGINT UNSIGNED NULL,
    product_type_code VARCHAR(30) NOT NULL COMMENT '商品类型枚举：hotel_room=酒店房型，scenic_ticket=景点票种，flight_cabin=航班舱位，train_seat=火车席位，bus_seat=汽车席位，transfer_service=接送服务',
    product_id BIGINT UNSIGNED NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    sale_amount DECIMAL(12, 2) NOT NULL,
    refunded_amount DECIMAL(12, 2) NULL,
    settlement_amount DECIMAL(12, 2) NULL,
    status_code VARCHAR(20) NOT NULL COMMENT '明细状态枚举：pending_payment=待支付，cancelled=已取消，paid=已支付，ticketed=已出票，refunded=已退款，completed=已完成',
    travel_time DATETIME NULL,
    travel_end_time DATETIME NULL,
    cancelled_at DATETIME NULL,
    paid_at DATETIME NULL,
    refunded_at DATETIME NULL,
    completed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_order_items_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_order_items_order_user FOREIGN KEY (order_id, user_id) REFERENCES orders (id, user_id),
    CONSTRAINT fk_order_items_order_type FOREIGN KEY (order_id, product_type_code) REFERENCES orders (id, order_type_code),
    CONSTRAINT fk_order_items_traveler FOREIGN KEY (traveler_id) REFERENCES travelers (id),
    CONSTRAINT fk_order_items_traveler_user FOREIGN KEY (traveler_id, user_id) REFERENCES travelers (id, user_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '订单明细';

CREATE TABLE order_coupon_usages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    order_item_id BIGINT UNSIGNED NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    template_id BIGINT UNSIGNED NOT NULL,
    user_coupon_id BIGINT UNSIGNED NOT NULL,
    order_type_code VARCHAR(30) NOT NULL COMMENT '订单类型枚举：hotel_room=酒店订单，scenic_ticket=景点门票订单，flight_cabin=机票订单，train_seat=火车票订单，bus_seat=汽车票订单，transfer_service=接送服务订单',
    discount_amount DECIMAL(12, 2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_order_coupon_usages_coupon (user_coupon_id),
    KEY idx_order_coupon_usages_order (order_id),
    CONSTRAINT fk_order_coupon_usages_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_order_coupon_usages_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id),
    CONSTRAINT fk_order_coupon_usages_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_order_coupon_usages_order_user FOREIGN KEY (order_id, user_id) REFERENCES orders (id, user_id),
    CONSTRAINT fk_order_coupon_usages_order_type FOREIGN KEY (order_id, order_type_code) REFERENCES orders (id, order_type_code),
    CONSTRAINT fk_order_coupon_usages_template FOREIGN KEY (template_id) REFERENCES coupon_templates (id),
    CONSTRAINT fk_order_coupon_usages_template_type FOREIGN KEY (template_id, order_type_code) REFERENCES coupon_templates (id, applicable_product_type),
    CONSTRAINT fk_order_coupon_usages_user_coupon FOREIGN KEY (user_coupon_id) REFERENCES user_coupons (id),
    CONSTRAINT fk_order_coupon_usages_coupon_template FOREIGN KEY (user_coupon_id, template_id) REFERENCES user_coupons (id, template_id),
    CONSTRAINT fk_order_coupon_usages_coupon_user FOREIGN KEY (user_coupon_id, user_id) REFERENCES user_coupons (id, user_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '订单用券记录';

CREATE TABLE order_promotion_details (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    order_item_id BIGINT UNSIGNED NULL,
    order_type_code VARCHAR(30) NOT NULL COMMENT '订单类型枚举：hotel_room=酒店订单，scenic_ticket=景点门票订单，flight_cabin=机票订单，train_seat=火车票订单，bus_seat=汽车票订单，transfer_service=接送服务订单',
    promotion_id BIGINT UNSIGNED NOT NULL,
    promotion_binding_id BIGINT UNSIGNED NOT NULL,
    promotion_rule_id BIGINT UNSIGNED NULL,
    discount_amount DECIMAL(12, 2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_order_promotion_details (order_id, order_item_id, promotion_id, promotion_rule_id),
    KEY idx_order_promotion_details_order (order_id),
    CONSTRAINT fk_order_promotion_details_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_order_promotion_details_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id),
    CONSTRAINT fk_order_promotion_details_promotion FOREIGN KEY (promotion_id) REFERENCES promotions (id),
    CONSTRAINT fk_order_promotion_details_order_type FOREIGN KEY (order_id, order_type_code) REFERENCES orders (id, order_type_code),
    CONSTRAINT fk_order_promotion_details_binding FOREIGN KEY (promotion_binding_id) REFERENCES promotion_bindings (id),
    CONSTRAINT fk_order_promotion_details_binding_type FOREIGN KEY (promotion_binding_id, order_type_code) REFERENCES promotion_bindings (id, product_type_code),
    CONSTRAINT fk_order_promotion_details_binding_promotion FOREIGN KEY (promotion_binding_id, promotion_id) REFERENCES promotion_bindings (id, promotion_id),
    CONSTRAINT fk_order_promotion_details_rule FOREIGN KEY (promotion_rule_id) REFERENCES promotion_rules (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '订单促销明细';

CREATE TABLE order_point_usages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    point_ledger_id BIGINT UNSIGNED NOT NULL,
    points_used INT NOT NULL,
    discount_amount DECIMAL(12, 2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_order_point_usages_ledger (point_ledger_id),
    KEY idx_order_point_usages_order (order_id),
    KEY idx_order_point_usages_user_ledger (user_id, point_ledger_id),
    CONSTRAINT fk_order_point_usages_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_order_point_usages_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_order_point_usages_order_user FOREIGN KEY (order_id, user_id) REFERENCES orders (id, user_id),
    CONSTRAINT fk_order_point_usages_ledger FOREIGN KEY (point_ledger_id) REFERENCES member_point_ledger (id),
    CONSTRAINT fk_order_point_usages_ledger_user FOREIGN KEY (point_ledger_id, user_id) REFERENCES member_point_ledger (id, user_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '订单积分使用';

CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_no VARCHAR(50) NOT NULL,
    order_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    payment_method_code VARCHAR(30) NOT NULL COMMENT '支付方式枚举：alipay=支付宝，wechat=微信支付，unionpay=银联',
    currency_code VARCHAR(10) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    status_code VARCHAR(20) NOT NULL COMMENT '支付状态枚举：pending=待支付，success=支付成功，failed=支付失败，closed=已关闭',
    paid_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_payments_no (payment_no),
    KEY idx_payments_id_order (id, order_id),
    KEY idx_payments_order_status (order_id, status_code),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_payments_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_payments_order_user FOREIGN KEY (order_id, user_id) REFERENCES orders (id, user_id),
    CONSTRAINT fk_payments_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '支付记录';

CREATE TABLE refund_requests (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    refund_request_no VARCHAR(50) NOT NULL,
    order_id BIGINT UNSIGNED NOT NULL,
    order_item_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    requested_amount DECIMAL(12, 2) NOT NULL,
    approved_amount DECIMAL(12, 2) NULL,
    status_code VARCHAR(20) NOT NULL COMMENT '退款申请状态枚举：pending=待处理，approved=审核通过，rejected=审核驳回，success=退款完成',
    requested_at DATETIME NOT NULL,
    processed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_refund_requests_no (refund_request_no),
    KEY idx_refund_requests_order_item (order_item_id),
    KEY idx_refund_requests_order_user_status (order_id, user_id, status_code),
    CONSTRAINT fk_refund_requests_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_refund_requests_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id),
    CONSTRAINT fk_refund_requests_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_refund_requests_order_user FOREIGN KEY (order_id, user_id) REFERENCES orders (id, user_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '退款申请';

CREATE TABLE refund_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    refund_no VARCHAR(50) NOT NULL,
    refund_request_id BIGINT UNSIGNED NOT NULL,
    order_id BIGINT UNSIGNED NOT NULL,
    order_item_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    payment_id BIGINT UNSIGNED NULL,
    currency_code VARCHAR(10) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    status_code VARCHAR(20) NOT NULL COMMENT '退款状态枚举：pending=退款处理中，success=退款成功，failed=退款失败',
    processed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_refund_records_no (refund_no),
    UNIQUE KEY uk_refund_records_request (refund_request_id),
    KEY idx_refund_records_order_status (order_id, status_code),
    KEY idx_refund_records_payment (payment_id),
    CONSTRAINT fk_refund_records_request FOREIGN KEY (refund_request_id) REFERENCES refund_requests (id),
    CONSTRAINT fk_refund_records_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_refund_records_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id),
    CONSTRAINT fk_refund_records_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_refund_records_payment FOREIGN KEY (payment_id) REFERENCES payments (id),
    CONSTRAINT fk_refund_records_order_user FOREIGN KEY (order_id, user_id) REFERENCES orders (id, user_id),
    CONSTRAINT fk_refund_records_payment_order FOREIGN KEY (payment_id, order_id) REFERENCES payments (id, order_id),
    CONSTRAINT fk_refund_records_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '退款记录';
