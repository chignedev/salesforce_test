import { LightningElement, api, wire, track } from 'lwc';
import getEngagementSummary
    from '@salesforce/apex/EngagementSummaryController.getEngagementSummary';
import createQuickFollowUpCall
    from '@salesforce/apex/EngagementSummaryController.createQuickFollowUpCall';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class EngagementSummary extends LightningElement {
    @api recordId;          // current Engagement Id

    @track summary;
    @track error;
    wiredResult;

    @wire(getEngagementSummary, { engagementId: '$recordId' })
    wiredSummary(result) {
        this.wiredResult = result;
        const { data, error } = result;

        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.summary = undefined;
            this.error = 'Error loading engagement summary';
        }
    }

    async handleFollowUp() {
        try {
            await createQuickFollowUpCall({ engagementId: this.recordId });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Quick follow-up call created.',
                    variant: 'success'
                })
            );

            // Refresh counts after creating the Task
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error creating follow-up call.',
                    variant: 'error'
                })
            );
        }
    }
}
