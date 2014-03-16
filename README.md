Overview
========

As of this writing, the Salesforce Lead Conversion process does not
allow users to pick the record types for the converted accounts/contacts/opportunities.

Salesforce instead uses the 'default' record type for those objects of the user's profile
who is performing the conversion. This assumption is not always valid, particularly
for users that have multiple record types available to them or that the ones they
use aren't actually flagged as 'default' on their profile (for example, the user's profile
has the master record type as default but the record types they actually use are granted
through permission sets).

This trigger is a workaround that leverages a custom setting to provide administrators
a way to provide record type conversion mappings while still using the out-of-the-box
lead conversion page. Compared to a fully custom visualforce solution, the aim of this
workaround is to allow simple one-to-one mappings from Lead record types to those of
the converted Account, Contact, and Opportunity.

Simply put, this trigger looks up a xref from the custom setting based on the lead's record type
then for each converted object (account, contact, opportunity) it updates their record types to
the values specified in the custom setting.

On the **Salesforce IdeaExchange**, the ability to choose a record type is a highly requested feature,
and I hope that this workaround will eventually not be necessary:
* https://success.salesforce.com/ideaView?id=08730000000Bra8AAC
* https://success.salesforce.com/answers?id=90630000000gvCcAAI

Read the Salesforce Docs on **Lead Conversion Process** to learn more:
* https://help.salesforce.com/HTViewHelpDoc?id=leads_notes.htm


Getting Started
===============

To implement this workaround in your salesforce org you will need to create a custom setting and deploy
the apex classes in this repository. The steps are very easy to do, and I'll outline the basic steps below.

1. Create a [Custom Setting](http://help.salesforce.com/apex/HTViewHelpDoc?id=cs_about.htm&language=en_US)
2. Create an [Apex Class](http://help.salesforce.com/apex/HTViewHelpDoc?id=code_define_package.htm&language=en_US)
3. Create an [Apex Trigger](http://help.salesforce.com/apex/HTViewHelpDoc?id=code_define_trigger.htm&language=en_US)
4. Create an [Apex Test](http://help.salesforce.com/apex/HTViewHelpDoc?id=code_run_tests.htm&language=en_US)


1. Create Custom Setting
------------------------

The custom setting is our cross-reference mapping between Lead record types and Account, Contact, and Opportunity
record types that we want to leverage during lead conversion process.

The code in this repository assumes you define a custom setting as follows:
[/images/custom_settings.png]
