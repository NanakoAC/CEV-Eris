/*
	The economy subsystem will handle everything related to finances, trade, wages, etc.

	In this initial implementation, it only handles wages
*/
SUBSYSTEM_DEF(economy)
	name = "Economy"
	init_order = INIT_ORDER_LATELOAD

	wait = 300 //Ticks once per 30 seconds
	var/payday_interval = 1 HOUR
	var/next_payday = 1 HOUR

/datum/controller/subsystem/economy/Initialize()
	.=..()

/datum/controller/subsystem/economy/fire()
	if (world.time >= next_payday)
		next_payday = world.time + payday_interval
		//Its payday time!
		do_payday()


/*
	Payday is handled in three stages.

1. Information gathering.
	We loop through everyone in the crew, check if they're not suspended or somesuch
	We make a note of all the people who are valid and active, along with how much they should be paid.
	This information is applied to departments in the pending payments list
	In addition each department also records its own fund request

	Note that dead people will still be paid automatically. Its the responsibility of command staff to
	manually suspend payment to the dead

2. Requesting funds:
	Each department will ask its appropriate source to send one lump sum, totalling the amount of all of its
	wage+fund requirements. This payment will either be made in full or rejected, no partial payments
	Requests from an external source will always succeed
	Request from another ship account will succeed if nothing prevents it. EG, adequate funds, not suspended, etc.

3. Payroll
	If the department account now has enough to cover all the wage requests, then they will all be paid.
	Again, no partial payments. Either everyone gets paid or nobody does

*/
/proc/do_payday()

	gather_payroll_info()
	request_payroll_funds()
	pay_wages()


//This is step 1, lets get the info
/proc/gather_payroll_info()


	//First gather the data for crew wages
	//Each record covers a specific crewman
	for(var/datum/data/record/R in data_core.general)
		world << "Checking data record [R]"

		/* TODO: Add in checks for suspension, dead, etc */




		//Ok lets get their job to determine how much we'll pay them
		var/datum/job/temp_job = SSjob.GetJob(R.fields["real_rank"])
		if(!istype(temp_job))
			temp_job = SSjob.GetJob("Assistant")
		if(!istype(temp_job))
			world << "Failed to find job"
			continue

		var/datum/department/department = all_departments[temp_job.department]
		if (!department)
			world << "Failed to find department"
			continue

		var/wage = temp_job.get_wage(R)
		if (wage <= 0)
			continue //This person will not be paid
		world << "Got wage of [wage]"

		//Alright we have their wage and their department, lets add it to the department's pending payments
		LAZYAPLUS(department.pending_wages, R, wage)


	//Lets request departmental funding next
	for (var/d in all_departments)
		var/datum/department/department = all_departments[d]
		if (department.account_budget)
			department.pending_budget_total += department.account_budget
		department.sum_wages() //Poke this in here to cache the wage totals


//Step 2: Requesting funds
//Here we attempt to transfer money from funding sources to department accounts
/proc/request_payroll_funds()
	world << "Requesting Payroll Funds"
	for (var/d in all_departments)
		var/datum/department/department = all_departments[d]
		world << "Requesting payroll for [department.id]"
		if (department.funding_type == FUNDING_NONE)
			world << "No funding"
			continue //This department gets no funding

		var/datum/money_account/source //Source account for internal funding

		var/reason = "Payroll Funding"
		var/terminal = "CEV Eris payroll system"

		//Alright, how much money are we requesting
		var/total_request = department.pending_wage_total + department.pending_budget_total

		//Now lets figure out if we can get our request filled
		var/can_pay = FALSE

		//External funding always succeeds
		if (department.funding_type == FUNDING_EXTERNAL)
			can_pay = TRUE
			terminal = "Hansa Galactic Link" //Magical wireless money transfer
			world << "External funding, canpay"

		//Internal funding, from another account on the ship
		else if (department.funding_type == FUNDING_INTERNAL)
			world << "Internal Funding"
			//First lets get the source account, its probably a department account
			source = department_accounts[department.funding_source]
			if (!source)
				//No? Maybe its been set to a personal account number
				source = get_account(department.funding_source)


			if (source)
				//Ok we have the account to draw from, next lets check if it has enough money
				if (source.money >= total_request)
					//It has enough, lets do this
					can_pay = TRUE

		if (can_pay)
			world << "We can pay"
			var/paid = FALSE

			//If its external, we use the deposit function to create money and put it in the department account
			if (department.funding_type == FUNDING_EXTERNAL)
				paid = deposit_to_account(department.account_number, department.funding_source, reason, terminal, total_request)

			else if (department.funding_type == FUNDING_INTERNAL)
				paid = transfer_funds(source.account_number, department.account_number, reason, terminal, total_request)

			if (paid)
				//The department has recieved its budget, so this is set zero now
				department.pending_budget_total = 0
		else
			//TODO: Some failure condition here
			//Email the account holder responsible#
			world << "We cannot pay!"
			continue




//Step 3: Actually paying the wages
/proc/pay_wages()
	world << "Paying out wages"
	var/total_paid = 0
	for (var/d in all_departments)
		var/datum/department/department = all_departments[d]
		if (!department.pending_wage_total)
			//No need to do anything if nobody's being paid here
			continue

		//Get our account
		var/datum/money_account/account = department_accounts[department.id]
		if (!account)
			continue

		//Check again that the department has enough. Because some departments, like guild, didnt request funds
		if (account.money <= department.pending_wage_total)
			//TODO Here: Email the account owner warning them that wages can't be paid
			continue

		//Here we go, lets pay them!
		for (var/datum/data/record/R in department.pending_wages)
			var/paid = FALSE
			//Get the crewman's account that we'll pay to
			var/crew_account_num = R.fields["pay_account"]
			var/amount = department.pending_wages[R]
			paid = transfer_funds(department.account_number, crew_account_num, "Payroll", "CEV Eris payroll system", amount)
			if (paid)
				total_paid += amount
				var/sender = "[department.name] account"
				if (department.funding_type == FUNDING_INTERNAL)
					//If this wage was funded internally, make sure the recipient knows that
					sender = "CEV Eris via [sender]"

				payroll_mail_account_holder(R, sender, amount)
		department.pending_wages = list() //All pending wages paid off
	command_announcement.Announce("Hourly crew wages have been paid, please check your email for details. In total the crew of CEV Eris have earned [total_paid] credits.", "Dispensation")

/proc/payroll_mail_account_holder(var/datum/data/record/R, var/sender)
	//In future, this will be expanded to include a report on penalties, bonuses and taxes that affected your wages

	var/address = R.fields["email"]

	//payroll_mailer