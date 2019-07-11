DELIMITER $$

USE `rtech`$$

DROP PROCEDURE IF EXISTS `profiles_extract_loans`$$

CREATE DEFINER=`rtech`@`%` PROCEDURE `profiles_extract_loans`()
BEGIN
     #Create the Loans table if it doesn't exist
     CREATE TABLE IF NOT EXISTS `rtech`.`loans`( 
         `id` INT NOT NULL AUTO_INCREMENT, 
         `profile_id` INT, 
         `amount_requested` DECIMAL(15,2), 
         `disbursment_status` VARCHAR(30), 
         `repayment_status` VARCHAR(30), 
         `description` TEXT, 
         `payment_id` VARCHAR(100), 
         `external_payment_id` VARCHAR(100), 
         `due_date` DATETIME, 
         `interest_accrued` DECIMAL(15,2),
          `interest_accrued_on_defaulting` DECIMAL(15,2), 
          `amount_due` DECIMAL(15,2), 
          `approved_date` DATETIME, 
          `created` DATETIME, 
          `modified` DATETIME,
           PRIMARY KEY (`id`)
      );
      #Read the JSON for the loans value(the value is stored in table profiles column profile_json)
      SELECT JSON_EXTRACT(profile_json,'$.more.profile.loan_history.original.more.loans') INTO @loans FROM `rtech`.`profiles`;
     
      #Loop through the loans set inserting into table
      SET @i = 0; #loop start value
      SELECT JSON_LENGTH(@loans) INTO @end; #loop max value
     
      WHILE @i < @end DO
           SELECT JSON_EXTRACT(@loans,CONCAT('$[',@i,']')) INTO @loan;
           #Insert loan into loans table (Using REPLACE in case of duplicate keys)
           REPLACE INTO `rtech`.`loans`(
               `id`,`profile_id`,`amount_requested`,`disbursment_status`,`repayment_status`,
               `description`,`payment_id`,`external_payment_id`,`due_date`,`interest_accrued`,
               `interest_accrued_on_defaulting`,`amount_due`,`approved_date`,`created`,`modified`)
           VALUES (
             JSON_EXTRACT(@loan,'$.id'),
             JSON_EXTRACT(@loan,'$.profile_id'),
             JSON_EXTRACT(@loan,'$.amount_requested'),
             JSON_EXTRACT(@loan,'$.disbursement_status'),
             JSON_EXTRACT(@loan,'$.repayment_status'),
             JSON_EXTRACT(@loan,'$.description'),
             JSON_EXTRACT(@loan,'$.payment_id'),
             JSON_EXTRACT(@loan,'$.external_payment_id'),
             CAST( JSON_UNQUOTE( JSON_EXTRACT(@loan,'$.due_date')) AS DATETIME),
             JSON_EXTRACT(@loan,'$.interest_accrued'),
             JSON_EXTRACT(@loan,'$.interest_accrued_on_defaulting'),
             JSON_EXTRACT(@loan,'$.amount_due'),
             CAST( JSON_UNQUOTE( JSON_EXTRACT(@loan,'$.approved_date')) AS DATETIME),
             CAST( JSON_UNQUOTE( JSON_EXTRACT(@loan,'$.created')) AS DATETIME),
             CAST( JSON_UNQUOTE( JSON_EXTRACT(@loan,'$.modified')) AS DATETIME)
          );
         SELECT @i + 1 INTO @i;
      END WHILE;
     
    END$$

DELIMITER ;