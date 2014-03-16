sfdc-lead-conversion-record-types
=================================

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

On the Salesforce IdeaExchange, the ability to choose a record type is a highly requested feature:
https://success.salesforce.com/ideaView?id=08730000000Bra8AAC
https://success.salesforce.com/answers?id=90630000000gvCcAAI

Read the Salesforce Docs on Lead Conversion Process to learn more:
https://help.salesforce.com/HTViewHelpDoc?id=leads_notes.htm
