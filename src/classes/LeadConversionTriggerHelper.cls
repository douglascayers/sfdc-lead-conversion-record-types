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

/**
 * Uses a custom setting to define the actual record types to use
 * for converted accounts, contacts, and opportunities rather than
 * relying on the 'default' record type specified on the user's profile.
 */
public with sharing class LeadConversionTriggerHelper {

    public class LeadConversionException extends Exception {}

    /**
     * Updates the record types of the converted account/contact/opportunity
     * of each lead based on the xref values in the Lead_Conversion_Record_Types_Settings__c.
     */
    public static void updateConvertedSObjectsRecordTypes( List<Lead> leads ) {

        List<SObject> recordsToUpdate = new List<SObject>();

        // will look up record types by the reference id on the lead object
        Map<ID, RecordTypeInfo> leadRecordTypeInfos = Lead.sObjectType.getDescribe().getRecordTypeInfosById();

        for ( Lead lead : leads ) {

            try {

                if ( lead.isConverted ) {

                    System.debug( 'attempting record types conversion for lead: ' + lead.id );

                    RecordTypeInfo leadRecordTypeInfo = leadRecordTypeInfos.get( lead.recordTypeId );

                    if ( lead.convertedAccountId != null ) {

                        SObject sobj = LeadConversionTriggerHelper.doRecordTypeConversion( leadRecordTypeInfo, lead.convertedAccountId );
                        recordsToUpdate.add( sobj );

                    }

                    if ( lead.convertedContactId != null ) {

                        SObject sobj = LeadConversionTriggerHelper.doRecordTypeConversion( leadRecordTypeInfo, lead.convertedContactId );
                        recordsToUpdate.add( sobj );

                    }

                    if ( lead.convertedOpportunityId != null ) {

                        SObject sobj = LeadConversionTriggerHelper.doRecordTypeConversion( leadRecordTypeInfo, lead.convertedOpportunityId );
                        recordsToUpdate.add( sobj );

                    }

                }

            } catch ( LeadConversionException ex ) {

                lead.addError( ex.getMessage() );

            }

        }

        LeadConversionTriggerHelper.updateRecordsInBatches( recordsToUpdate, 200 );

    }

    // --------------------------------------------------------------------------------------------

    /**
     * Looks up the conversion record type xref value for the converted sobject (account, contact, oppty)
     * based on configuration in the Lead_Conversion_Record_Types_Settings__c.
     *
     * @param leadRecordTypeInfo
     *      record type of the lead, used to look up the xref custom setting to use
     * @param convertedSObjectId
     *      id to the converted object whose record type to change
     *
     * @return an SObject with ID and RecordTypeId fields set, should be added to a list for batch updating
     *
     * @throws LeadConversionException if missing configuration or unable to compute record type conversion
     */
    private static SObject doRecordTypeConversion( RecordTypeInfo leadRecordTypeInfo, ID convertedSObjectId ) {

        System.debug( 'attempting record type conversion for sobject: ' + convertedSObjectId );

        SObjectType sObjectType = convertedSObjectId.getSObjectType();

        RecordTypeInfo conversionRecordTypeInfo = LeadConversionTriggerHelper.getRecordTypeInfoConversionForSObjectType( leadRecordTypeInfo, sObjectType );

        if ( conversionRecordTypeInfo != null ) {

            SObject sobj = sObjectType.newSObject( convertedSObjectId );
            sobj.put( 'recordTypeId', conversionRecordTypeInfo.getRecordTypeId() );
            return sobj;

        } else {

            System.debug( LoggingLevel.ERROR, 'No ' + sObjectType.getDescribe().getName() + ' record type for lead conversion: ' + leadRecordTypeInfo.getName() );
            throw new LeadConversionException( 'No ' + sObjectType.getDescribe().getName() + ' record type for lead conversion: ' + leadRecordTypeInfo.getName() + '. Please contact your System Administrator' );

        }

    }

    /**
     * Convenience method to return the record type conversion value for particular sobjecttype from the custom setting.
     */
    private static RecordTypeInfo getRecordTypeInfoConversionForSObjectType( RecordTypeInfo leadRecordTypeInfo, Schema.SObjectType sObjectType ) {

        RecordTypeInfo xrefRecordTypeInfo = null;

        // retrieve xref custom settings for this lead's record type
        Lead_Conversion_Record_Types_Settings__c xref = Lead_Conversion_Record_Types_Settings__c.getInstance( leadRecordTypeInfo.getName() );

        if ( xref != null ) {

            // get record type infos supported by the converted sobject type
            Map<String, RecordTypeInfo> sObjectRecordTypeInfos = sObjectType.getDescribe().getRecordTypeInfosByName();

            if ( Account.sObjectType == sObjectType ) {
                xrefRecordTypeInfo = sObjectRecordTypeInfos.get( xref.Account_Record_Type_Name__c );
            }
            else if ( Contact.sObjectType == sObjectType ) {
                xrefRecordTypeInfo = sObjectRecordTypeInfos.get( xref.Contact_Record_Type_Name__c );
            }
            else if ( Opportunity.sObjectType == sObjectType ) {
                xrefRecordTypeInfo = sObjectRecordTypeInfos.get( xref.Opportunity_Record_Type_Name__c );
            }

        }

        return xrefRecordTypeInfo;
    }

    /**
     * Chunks the original list of sobjects into batches when issuing updates.
     * Standard batch size is 200; modify as needed for performance.
     */
    private static void updateRecordsInBatches( List<SObject> recordsToUpdate, Integer batchSize ) {

        List<SObject> batchList = new List<SObject>();

        for ( SObject record : recordsToUpdate ) {

            batchList.add( record );

            if ( batchList.size() >= batchSize ) {
                update batchList;
                batchList.clear();
            }

        }

        if ( batchList.size() > 0 ) {
            update batchList;
            batchList.clear();
        }

    }

}