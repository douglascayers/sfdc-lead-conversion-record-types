/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 @DouglasCAyers
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@isTest
private class LeadConversionTriggerHelperTest {

    // salesforce does not allow DML operations on RecordType object
    // so our tests can't create record types, we must rely on ones in the org.
    // since each org will have different record type names, just configure these
    // constants with names appropriate for your org. The test methods will
    // use them when configuring the xref custom setting, etc.
    final static RecordTypeInfo LEAD_RECORD_TYPE_INFO = Lead.sObjectType.getDescribe().getRecordTypeInfos().get(0);
    final static RecordTypeInfo ACCOUNT_RECORD_TYPE_INFO = Account.sObjectType.getDescribe().getRecordTypeInfos().get(0);
    final static RecordTypeInfo CONTACT_RECORD_TYPE_INFO = Contact.sObjectType.getDescribe().getRecordTypeInfos().get(0);
    final static RecordTypeInfo OPPORTUNITY_RECORD_TYPE_INFO = Opportunity.sObjectType.getDescribe().getRecordTypeInfos().get(0);

    @isTest
    static void test_it_should_fail_when_missing_xref_config() {

        Lead newLead = new Lead(
            firstName = 'Marc',
            lastName = 'Benioff',
            company = 'Salesforce'
        );

        insert newLead;

        Test.startTest();

        try {

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId( newLead.id );

            LeadStatus convertStatus = [ SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1 ];
            lc.setConvertedStatus( convertStatus.MasterLabel );

            Database.LeadConvertResult lcr = Database.convertLead( lc );
            System.assert( lcr.isSuccess() == false );

        } catch ( DmlException ex ) {

            System.assert( ex.getMessage().contains( 'FIELD_CUSTOM_VALIDATION_EXCEPTION' ) );
            System.assert( ex.getMessage().contains( 'Validation error on Lead' ) );
            System.assert( ex.getMessage().contains( 'record type for lead conversion' ) );

        }

        Test.stopTest();

    }

    @isTest
    static void test_it_should_fail_when_missing_sobject_xref() {

        Test.startTest();

        try {

            Lead_Conversion_Record_Types_Settings__c xref = new Lead_Conversion_Record_Types_Settings__c(
                name = LEAD_RECORD_TYPE_INFO.getName()
            );

            insert xref;

        } catch ( DmlException ex ) {

            System.assert( ex.getMessage().contains( 'REQUIRED_FIELD_MISSING' ) );
            System.assert( ex.getMessage().contains( 'Account_Record_Type_Name__c' ) );
            System.assert( ex.getMessage().contains( 'Contact_Record_Type_Name__c' ) );

        }

        Test.stopTest();

    }

    @isTest
    static void test_it_should_update_sobject_record_types() {

        Lead_Conversion_Record_Types_Settings__c xref = new Lead_Conversion_Record_Types_Settings__c(
            name = LEAD_RECORD_TYPE_INFO.getName(),
            account_record_type_name__c = ACCOUNT_RECORD_TYPE_INFO.getName(),
            contact_record_type_name__c = CONTACT_RECORD_TYPE_INFO.getName(),
            opportunity_record_type_name__c = OPPORTUNITY_RECORD_TYPE_INFO.getName()
        );

        insert xref;

        Lead newLead = new Lead(
            firstName = 'Marc',
            lastName = 'Benioff',
            company = 'Salesforce',
            recordTypeId = LEAD_RECORD_TYPE_INFO.getRecordTypeId()
        );

        insert newLead;

        Test.startTest();

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId( newLead.id );

        LeadStatus convertStatus = [ SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1 ];
        lc.setConvertedStatus( convertStatus.MasterLabel );

        Database.LeadConvertResult lcr = Database.convertLead( lc );
        System.assert( lcr.isSuccess() );

        Test.stopTest();

        Lead convertedLead = [ SELECT id, convertedAccountId, convertedContactId, convertedOpportunityId FROM Lead WHERE id = :lc.leadId ];

        Account newAccount = [ SELECT id, recordTypeId FROM Account WHERE id = :convertedLead.convertedAccountId ];
        System.assert( newAccount.recordTypeId == ACCOUNT_RECORD_TYPE_INFO.getRecordTypeId() );

        Contact newContact = [ SELECT id, recordTypeId FROM Contact WHERE id = :convertedLead.convertedContactId ];
        System.assert( newContact.recordTypeId == CONTACT_RECORD_TYPE_INFO.getRecordTypeId() );

        Opportunity newOpportunity = [ SELECT id, recordTypeId FROM Opportunity WHERE id = :convertedLead.convertedOpportunityId ];
        System.assert( newOpportunity.recordTypeId == OPPORTUNITY_RECORD_TYPE_INFO.getRecordTypeId() );

    }

}