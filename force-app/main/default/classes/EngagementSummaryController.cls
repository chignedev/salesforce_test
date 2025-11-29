public with sharing class EngagementSummaryController {

    public class EngagementSummaryDTO {
        @AuraEnabled public String engagementName;
        @AuraEnabled public Decimal opportunityAmount;
        @AuraEnabled public Integer completedTasks;
        @AuraEnabled public Integer upcomingEvents;
    }

    @AuraEnabled(cacheable=true)
    public static EngagementSummaryDTO getEngagementSummary(Id engagementId) {
        // Get engagement and related opportunity
        Engagement__c eng = [
            SELECT Id,
                   Name,
                   Related_Opportunity__c,
                   Related_Opportunity__r.Amount
            FROM Engagement__c
            WHERE Id = :engagementId
            LIMIT 1
        ];

        EngagementSummaryDTO dto = new EngagementSummaryDTO();
        dto.engagementName = eng.Name;
        dto.opportunityAmount =
            (eng.Related_Opportunity__c != null)
            ? eng.Related_Opportunity__r.Amount
            : null;

        // Count completed Tasks related to this Engagement
        Integer completedTasks = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :engagementId
              AND Status = 'Completed'
        ];
        dto.completedTasks = completedTasks;

        // Count upcoming Events related to this Engagement
        Integer upcomingEvents = [
            SELECT COUNT()
            FROM Event
            WHERE WhatId = :engagementId
              AND StartDateTime >= :System.now()
        ];
        dto.upcomingEvents = upcomingEvents;

        return dto;
    }

    @AuraEnabled
    public static void createQuickFollowUpCall(Id engagementId) {
        // Get Engagement name (and primary contact if you want to relate it)
        Engagement__c eng = [
            SELECT Id, Name, Primary_Contact__c
            FROM Engagement__c
            WHERE Id = :engagementId
            LIMIT 1
        ];

        Task t = new Task();
        t.Subject = 'Follow-up on ' + eng.Name;
        t.ActivityDate = Date.today().addDays(1);    // tomorrow
        t.Type = 'Call';
        t.WhatId = eng.Id;                           // related to Engagement

        if (eng.Primary_Contact__c != null) {
            t.WhoId = eng.Primary_Contact__c;        // optional but nice
        }

        insert t;
    }
}