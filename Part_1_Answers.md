## 1. Using your database model as a blueprint, create a database schema for each of your tables and relationships. Remember to specify data types, primary keys, foreign keys, and any other constraints you defined.

Schema can be found here: https://app.quickdatabasediagrams.com/#/d/WDYcE3
![ERD](ERD.png?raw=true)

To see the exported postgres file please see [Schema.sql](Schema.sql)

## 2. How can you isolate (or group) the transactions of each cardholder?

You can do this with two methods the secon method being the better method:

1. Using Subqueries, you would need to change the name to the name of the card holder, currently this code gets all the transactions related to Shane Shaffer:

```SQL
Select * from transaction 
where transaction.card in( 
	Select credit_card.card from credit_card 
	where credit_card.cardholder_id in(
		Select card_holder.id from card_holder 
		where card_holder.name = 'Shane Shaffer'
	) 
)
```
2. Using joins and then creating a view for that query so that you can then do a simple select from the view where the card holder is the desired individual:

```SQL
CREATE VIEW  card_holder_transactions AS
SELECT card_holder.id
,card_holder.name
,credit_card.card
,transaction.date
,transaction.amount
FROM card_holder
LEFT JOIN credit_card
ON card_holder.id = credit_card.cardholder_id
LEFT JOIN transaction
ON credit_card.card = transaction.card

SELECT * FROM card_holder_transactions WHERE name = 'Shane Shaffer'

```
## 3. Consider the time period 7:00 a.m. to 9:00 a.m.

  * What are the top 100 highest transactions during this time period?

  * Do you see any fraudulent or anomalous transactions?

  * If you answered yes to the previous question, explain why you think there might be fraudulent transactions during this time frame.


The SQL query used to obtain this information is as follows:
```SQL
Select * from transaction
where CAST(transaction.date AS time) BETWEEN '07:00:00' AND '09:00:00'
order by amount DESC
LIMIT 100;
```
You can see the output of the quere in the [100Highesttransactionsfrom7to9.csv](100Highesttransactionsfrom7to9.csv) file

To answer whether the there were unusual purchases I needed some context into what was considered a normal purchase so I wrote a the following query to find the average amount spent per merchant and join it to the previous query to find the top 100 transactions during 7 to 9 AM THe output of this query can be found in [100_Highest_Transactions_From_7to9_with_avg_amount.csv](100_Highest_Transactions_From_7to9_with_avg_amount.csv):

```SQL
--Getting the highest transaction amount for transaction
--occuring during 7 A.M. to 9 A.M. 
CREATE VIEW TOP_TRANSACTIONS_DURING_PERIOD AS
Select * from transaction
where CAST(transaction.date AS time) BETWEEN '07:00:00' AND '09:00:00'
order by amount DESC
LIMIT 100;

--Getting the average amount spent per merchant
CREATE VIEW AVG_SPENDING_PER_MERCHANT AS
Select id_merchant
,avg(amount) AS avg_amount
FROM transaction
GROUP BY id_merchant;

--Joining the highest transaction amounts during 7 A.M. to 9 A.M.
--with the average amount spent per merchant
SELECT TOP_TRANSACTIONS_DURING_PERIOD.* 
,AVG_SPENDING_PER_MERCHANT.avg_amount
FROM TOP_TRANSACTIONS_DURING_PERIOD
LEFT JOIN AVG_SPENDING_PER_MERCHANT
ON TOP_TRANSACTIONS_DURING_PERIOD.id_merchant = AVG_SPENDING_PER_MERCHANT.id_merchant
ORDER BY TOP_TRANSACTIONS_DURING_PERIOD.amount DESC;
```
Looking at the data I can say that the first 8 transaction in the output raise suspecion as the amount spent is magnitudes more than the average. I believe that this time frame, 7:00 am to 9:00 am, is a go to timeframe for checking for fraud becuase this is typically when stores open and fraudsters would most likely try to profit off there fraud when there is fewer people.  

## 4. Count the transactions that are less than $2.00 per cardholder. Is there any evidence to suggest that a credit card has been hacked? Explain your rationale.

To answer this question I am utilizing the card_holder_transactions view that I created during the first question and using the following query to pull a count of all sub $2.00 transactions per card holder. The output of the query can be found in [Sub_2_dollar_transaction_count.csv](Sub_2_dollar_transaction_count.csv).

```SQL
SELECT id
,COUNT(amount) as num_transaction_less_than_2
FROM card_holder_transactions
WHERE amount < 2
GROUP BY id
ORDER BY num_transaction_less_than_2 DESC;
```

It is hard to conclude if there is any fraud based on the count since there is no card holders with a big gap between transaction counts.

## 5. What are the top 5 merchants prone to being hacked using small transactions?

The merchants most prone to be hacked with this technique would be the merchants wiht the most transations as it would be easier to miss a small transaction. In order to figure which merchant this is we use the following query:

```SQL
SELECT transaction.id_merchant
,merchant.name
,COUNT(transaction.amount) AS count_of_transactions
FROM transaction
LEFT JOIN merchant
ON  transaction.id_merchant = merchant.id
GROUP BY id_merchant
,merchant.name
ORDER BY count_of_transactions DESC
LIMIT 5;
```
The output of this query is:

```
"Riggs-Adams"
"White-Hall"
"Jarvis-Turner"
"Ruiz-Anderson"
"Johnson and Sons"
```
