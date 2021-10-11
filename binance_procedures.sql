# Процудура регистрации нового пользователя

DROP PROCEDURE IF EXISTS new_user_reg;

DELIMITER $$

CREATE PROCEDURE new_user_reg(
	firstname VARCHAR(50), lastname VARCHAR(50), email VARCHAR(50), phone BIGINT, pass_hash VARCHAR(100), birthday DATE, gender VARCHAR(10), residence VARCHAR(100))
BEGIN
	DECLARE reg_result VARCHAR(255);
	
	DECLARE `_rollback` BIT DEFAULT 0;

	DECLARE error_code VARCHAR(100);

	DECLARE error_text VARCHAR(100);

	DECLARE CONTINUE handler FOR SQLEXCEPTION
	BEGIN
		SET `_rollback` = 1;
	
		GET stacked DIAGNOSTICS CONDITION 1
			error_code = RETURNED_SQLSTATE, error_text = MESSAGE_TEXT;	
		
		SET reg_result = CONCAT('ERROR: ', error_code, ', ', error_text);
	END;
	
	
	START TRANSACTION;
		INSERT INTO accounts (firstname, lastname, email, phone, pass_hash, birthday, gender)
		VALUES (firstname, lastname, email, phone, pass_hash, birthday, gender);
	
		INSERT INTO verification_info (account_id, residence)
		VALUES (LAST_INSERT_ID(), residence);
	
		UPDATE accounts SET is_blocked = 1 WHERE id = LAST_INSERT_ID();
			
	IF `_rollback` = 1 THEN
		ROLLBACK;
	
	ELSE
		SET reg_result = 'registration ok';
		
		INSERT INTO user_notification (account_id, body)
		VALUES (ac_id, 'Поздравляем с регистрацией. Ваша учётная запись будет неактивна, пока вы не пройдёте верификацию.');
		
		COMMIT;
	
	END IF;

	SELECT reg_result;
	
END$$

DELIMITER ;

# Процедура добавления информации для верификации аккаунта

DROP PROCEDURE IF EXISTS binance.verification_info_update;

DELIMITER $$

CREATE PROCEDURE binance.verification_info_update(
	ac_id BIGINT, pass_file VARCHAR(100), location_file VARCHAR(100), selfphoto_file VARCHAR(100))
BEGIN
	
	DECLARE ver_result VARCHAR(255);
	
	DECLARE `_rollback` BIT DEFAULT 0;

	DECLARE error_code VARCHAR(100);

	DECLARE error_text VARCHAR(100);

	DECLARE CONTINUE handler FOR SQLEXCEPTION
	BEGIN
		SET `_rollback` = 1;
	
		GET stacked DIAGNOSTICS CONDITION 1
			error_code = RETURNED_SQLSTATE, error_text = MESSAGE_TEXT;	
		
		SET ver_result = CONCAT('ERROR: ', error_code, ', ', error_text);
	END;
	
	
	START TRANSACTION;
		UPDATE verification_info SET 
			passport_docs_file = pass_file,
			location_docs_file = location_file,
			photo_verification_file = selfphoto_file,
			verification_status = 'in_process'
		WHERE account_id = ac_id;
	
		UPDATE accounts SET is_blocked = 0 WHERE id = ac_id;
			
	IF `_rollback` = 1 THEN
		ROLLBACK;
	
	ELSE
		SET ver_result = 'verification in process';
	
		INSERT INTO user_notification (account_id, body)
		VALUES (ac_id, 'Ваши документы на проверке. Это может занять несколько дней.');
		
		COMMIT;
	
	END IF;

	SELECT ver_result;
	
END$$
DELIMITER ;

# Процедура сделки

DROP PROCEDURE IF EXISTS deal;

DELIMITER $$

CREATE PROCEDURE deal(resp_id BIGINT, ord_id BIGINT)
BEGIN
	
	DECLARE deal_res VARCHAR(255);

	DECLARE `_rollback` BIT DEFAULT 0;

	DECLARE error_code VARCHAR(100);

	DECLARE error_text VARCHAR(100);

	DECLARE bay_coin_id BIGINT;

	DECLARE sale_coin_id BIGINT;

	DECLARE bay_coin_sum FLOAT;

	DECLARE sale_coin_sum FLOAT;

	DECLARE CONTINUE handler FOR SQLEXCEPTION
	BEGIN
		SET `_rollback` = 1;
	
		GET stacked DIAGNOSTICS CONDITION 1
			error_code = RETURNED_SQLSTATE, error_text = MESSAGE_TEXT;	
		
		SET deal_res = CONCAT('ERROR: ', error_code, ', ', error_text);
	END;
	
	SET bay_coin_id = (
		SELECT tp.coin_id_a
		FROM traiding_orders to2
		JOIN traiding_pairs tp ON tp.id = to2.traiding_pair_id
		WHERE to2.id = ord_id);
	
	SET sale_coin_id = (
		SELECT tp.coin_id_b
		FROM traiding_orders to2
		JOIN traiding_pairs tp ON tp.id = to2.traiding_pair_id
		WHERE to2.id = ord_id);
	
	SET bay_coin_sum = (
		SELECT order_sum
		FROM traiding_orders
		WHERE id = 1);
	
	SET sale_coin_sum = (
		SELECT tro.order_sum * tp.pair_course
		FROM traiding_orders AS tro
		JOIN traiding_pairs AS tp ON tp.id = tro.traiding_pair_id 
		WHERE tro.id = 1);
	
	START TRANSACTION;

		IF (SELECT type_order FROM traiding_orders WHERE id = ord_id) = 'bay' THEN
		
			UPDATE wallets SET balance = balance + bay_coin_sum 
				WHERE account_id = resp_id 
				AND coin_id = bay_coin_id;
			
			UPDATE wallets SET balance = balance - sale_coin_sum
				WHERE account_id = resp_id
				AND coin_id = sale_coin_id;
			
			UPDATE wallets SET balance = balance - bay_coin_sum 
				WHERE account_id = (SELECT account_id FROM traiding_orders WHERE id = ord_id) 
				AND coin_id = bay_coin_id;
			
			UPDATE wallets SET balance = balance + sale_coin_sum 
				WHERE account_id = (SELECT account_id FROM traiding_orders WHERE id = ord_id) 
				AND coin_id = sale_coin_id;
			
		ELSE
		
			UPDATE wallets SET balance = balance - bay_coin_sum 
				WHERE account_id = resp_id 
				AND coin_id = bay_coin_id;
			
			UPDATE wallets SET balance = balance + sale_coin_sum
				WHERE account_id = resp_id
				AND coin_id = sale_coin_id;
			
			UPDATE wallets SET balance = balance + bay_coin_sum 
				WHERE account_id = (SELECT account_id FROM traiding_orders WHERE id = ord_id) 
				AND coin_id = bay_coin_id;
			
			UPDATE wallets SET balance = balance - sale_coin_sum 
				WHERE account_id = (SELECT account_id FROM traiding_orders WHERE id = ord_id) 
				AND coin_id = sale_coin_id;
			
		END IF;
	
		IF (SELECT is_closed FROM traiding_orders WHERE id = ord_id) = 1 THEN 
			SET deal_res = 'Ордер закрыт.';
			ROLLBACK;
		
		ELSEIF `_rollback` = 1 THEN
			ROLLBACK;
		
		ELSE
			UPDATE traiding_orders SET is_closed = 1 WHERE id = ord_id;
			SET deal_res = 'OK!';
			COMMIT;
		
		END IF;
	
	SELECT deal_res AS 'result';

END$$

DELIMITER ;