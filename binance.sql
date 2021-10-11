################
### ОПИСАНИЕ ###
################
/*
База данных для криптовалютной биржи.
Хранит в себе информацию о пользователях, их данные верификации, курсы обмена криптовалюты,
актуальную информацию о ордерах (как открытых, так уже и закрытых). Так же ордера по внесению 
фиатных средств на счёт аккаунта. При внесении изменений в аккаунты, информация обновляется.
При открытии торгового ордера заносится запись. При закрытии сделки информация о балансе 
криптокошельков пользователей изменяется. 
*/

DROP DATABASE IF EXISTS binance;
CREATE DATABASE binance;
USE binance;

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
	id SERIAL,
	firstname VARCHAR(50) NOT NULL,
	lastname VARCHAR(50) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	phone BIGINT UNSIGNED NOT NULL UNIQUE,
	pass_hash VARCHAR(100) NOT NULL UNIQUE,
	birthday DATE NOT NULL,
	gender ENUM('male','female') NOT NULL,
	is_blocked BIT DEFAULT 0,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW()
) COMMENT 'Аккаунты пользователей';

DROP TABLE IF EXISTS verification_info;
CREATE TABLE verification_info (
	account_id BIGINT UNSIGNED NOT NULL UNIQUE,
	residence VARCHAR(50) NOT NULL,
	passport_docs_file VARCHAR(255) UNIQUE,
	location_docs_file VARCHAR(255) UNIQUE,
	photo_verification_file VARCHAR(255) UNIQUE,
	verification_status ENUM('verified','in_process','declined') DEFAULT NULL,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW(),
	FOREIGN KEY (account_id) REFERENCES accounts(id)
) COMMENT 'Информация и документы верификации аккаунтов';

DROP TABLE IF EXISTS payment_methods_type;
CREATE TABLE payment_methods_type (
	id SERIAL,
	name VARCHAR(100),
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW(),
	INDEX payment_methods_type_idx(name)
) COMMENT 'Типы выплат';

DROP TABLE IF EXISTS payment_methods;
CREATE TABLE payment_methods (
	id SERIAL,
	account_id BIGINT UNSIGNED NOT NULL,
	payment_type BIGINT UNSIGNED NOT NULL,
	account_number BIGINT UNSIGNED NOT NULL,
	balance DECIMAL UNSIGNED,
	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (payment_type) REFERENCES payment_methods_type(id)
) COMMENT 'Способы оплаты';

DROP TABLE IF EXISTS coins;
CREATE TABLE coins (
	id SERIAL,
	coin_name VARCHAR(50) UNIQUE NOT NULL,
	coin_code VARCHAR(5) UNIQUE NOT NULL,
	created_at DATETIME DEFAULT NOW(),
	INDEX coin_code_idx(coin_code),
	INDEX coin_name_idx(coin_name)
) COMMENT 'Список криптовалют';

DROP TABLE IF EXISTS wallets;
CREATE TABLE wallets (
	id SERIAL,
	account_id BIGINT UNSIGNED NOT NULL,
	coin_id BIGINT UNSIGNED NOT NULL,
	balance FLOAT UNSIGNED,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW(),
	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (coin_id) REFERENCES coins(id)
) COMMENT 'Кошельки криптовалют пользователей';

DROP TABLE IF EXISTS traiding_pairs;
CREATE TABLE traiding_pairs (
	id SERIAL,
	coin_id_a BIGINT UNSIGNED NOT NULL,
	coin_id_b BIGINT UNSIGNED NOT NULL,
	pair_course FLOAT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW(),
	FOREIGN KEY (coin_id_a) REFERENCES coins(id),
	FOREIGN KEY (coin_id_b) REFERENCES coins(id),
	INDEX traiding_pairs (coin_id_a, coin_id_b)
) COMMENT 'Торговые пары криптовалют';

DROP TABLE IF EXISTS traiding_orders;
CREATE TABLE traiding_orders (
	id SERIAL,
	account_id BIGINT UNSIGNED NOT NULL,
	traiding_pair_id BIGINT UNSIGNED NOT NULL,
	order_sum BIGINT UNSIGNED NOT NULL,
	type_order ENUM('bay','sale') NOT NULL,
	is_closed BIT DEFAULT 0, 
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW(),
	FOREIGN KEY (account_id) REFERENCES accounts(id),
	FOREIGN KEY (traiding_pair_id) REFERENCES traiding_pairs(id)
) COMMENT 'Ордера сделок';

DROP TABLE IF EXISTS fiat_orders;
CREATE TABLE fiat_orders (
	id SERIAL,
	payment_method_id BIGINT UNSIGNED NOT NULL,
	order_sum BIGINT UNSIGNED NOT NULL,
	type_order ENUM('deposit','withdraw') NOT NULL,
	is_closed BIT DEFAULT 0,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW(),
	FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
) COMMENT 'Ордера вывода или ввода средств';

DROP TABLE IF EXISTS user_notification;
CREATE TABLE user_notification (
	id SERIAL,
	account_id BIGINT UNSIGNED NOT NULL,
	body TEXT, 
	is_readed BIT DEFAULT 0,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE NOW(),
	FOREIGN KEY (account_id) REFERENCES accounts(id)
) COMMENT 'Системные уведомления';

DROP TABLE IF EXISTS news;
CREATE TABLE news (
	id SERIAL,
	body TEXT,
	created_at DATETIME DEFAULT NOW()
) COMMENT 'Новости с торговой площадки';