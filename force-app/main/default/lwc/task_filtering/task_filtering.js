import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getTasksForCareProgramEnrollees from '@salesforce/apex/TaskHandler.getTasksForCareProgramEnrollees';
import { NavigationMixin } from 'lightning/navigation';


export default class TaskHandler extends NavigationMixin(LightningElement) {
    enrollees;
    @api recordId;
    tasks;
    filteredTasks = [];
    allTasks;
    error;
    enrolleeId;
    formattedCreatedDate;
    draftValues = [];
    selectedSubject = '--None--';
    isComboboxFocused = false;
    recordStatus;
    recordViewStatus = true; // Track whether "View All" button is clicked
    viewStatus = false; // Track whether "View All" button is clicked


    subjectOptions = [
        { label: '--None--', value: '--None--' },
        { label: 'Benefit Investigation', value: 'Benefit Investigation' },
        { label: 'Call', value: 'Call' },
        { label: 'Expiration', value: 'Expiration' },
        { label: 'Follow-Up HCP Interaction', value: 'Follow-Up HCP Interaction' },
        { label: 'HCP Interaction', value: 'HCP Interaction' },
        { label: 'Patient Interaction', value: 'Patient Interaction' },
        { label: 'Payer Interaction', value: 'Payer Interaction' },
        { label: 'Quarterly Call', value: 'Quarterly Call' },
        { label: 'Send Letter', value: 'Send Letter' },
        { label: 'Send Quote', value: 'Send Quote' },
        { label: 'SP Interaction', value: 'SP Interaction' },
        { label: 'Benefit investigation - HCP interaction', value: 'Benefit investigation - HCP interaction' },
        { label: 'Internal interaction', value: 'Internal interaction' },
        { label: 'Benefit reverification', value: 'Benefit reverification' },
        { label: 'Benefit investigation - Patient interaction', value: 'Benefit investigation - Patient interaction' },
        { label: 'Missed shipment - SP interaction', value: 'Missed shipment - SP interaction' },
        { label: 'Missed shipment - HCP interaction', value: 'Missed shipment - HCP interaction' },
        { label: 'Missed shipment - Patient interaction', value: 'Missed shipment - Patient interaction' },
        { label: 'Flare', value: 'Flare' },
        { label: 'Consent expiring', value: 'Consent expiring' },
        { label: 'Reconsent for 18th birthday', value: 'Reconsent for 18th birthday' },
        { label: 'Missing Information - HCP Follow-Up', value: 'Missing Information - HCP Follow-Up' },
        { label: 'Missing Information - Patient Follow-Up', value: 'Missing Information - Patient Follow-Up' },
        { label: 'HCP Interaction - Insurance Follow-Up', value: 'HCP Interaction - Insurance Follow-Up' },
        { label: 'Prior Authorization Payer Follow-up', value: 'Prior Authorization Payer Follow-up' },
        { label: 'Internal Interaction - PA Follow-Up', value: 'Internal Interaction - PA Follow-Up' },
        { label: 'Internal Interaction - TPAP Eligibility', value: 'Internal Interaction - TPAP Eligibility' },
        { label: 'HCP Interaction - Advise PA', value: 'HCP Interaction - Advise PA' },
        { label: 'HCP Interaction- Advise Appeal', value: 'HCP Interaction- Advise Appeal' },
        { label: 'Internal Interaction - Appeal Follow-up', value: 'Internal Interaction - Appeal Follow-up' },
        { label: 'HCP Interaction - Discuss PA Appeal Requirements', value: 'HCP Interaction - Discuss PA Appeal Requirements' },
        { label: 'Internal Interaction - Review for PAP Eligibility', value: 'Internal Interaction - Review for PAP Eligibility' },
        { label: 'Task - Assign Copay Card', value: 'Task - Assign Copay Card' },
        { label: 'New Shipment', value: 'New Shipment' },
        // Add more subject options as needed
    ];



    @wire(getTasksForCareProgramEnrollees, { careProgramEnrolleeId: '$recordId', selectedSubject: '$selectedSubject' })
    wiredTasks(result) {
        if (result.data !== undefined) {
            const data = result.data;
            this.allTasks = data.map(task => {
                // Extract only the date part from the CreatedDate and convert it to ISO string
                const createdDateISO = new Date(task.CreatedDate).toISOString().split('T')[0];
                return { ...task, formattedCreatedDate: createdDateISO };
            });
           
            this.filteredTasks = this.allTasks;
            this.recordStatus = true;
            if (this.selectedSubject !== '--None--') {
                this.filteredTasks = this.filteredTasks.filter(task => task.Subject === this.selectedSubject);
                this.filteredTasks = this.filteredTasks.map(task => ({ ...task, formattedCreatedDate: task.CreatedDate }));
                this.recordStatus = this.filteredTasks.length > 0;
            } else if (this.recordViewStatus === true) {
                this.viewStatus = this.filteredTasks.length > 10;
                this.filteredTasks = this.filteredTasks.slice(0, 10);
            }
        }
    }

    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();
        this.filteredTasks = this.filteredTasks.filter(task => 
             task.Subject && task.Subject.toLowerCase().includes(searchTerm)
        );
    }


    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.recordId;
        this.navigateToRecordPage(recordId);
    }


    navigateToRecords(event) {
        const recordId = event.currentTarget.dataset.recordId;
        this.navigateToRecordPage(recordId);
    }

    navigateToRecordPage(recordId) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            actionName: 'view'
        }
    });
}

    handleInputChange(event) {
        if (!event.target.value) {
            this.filteredTasks = this.wiredTasks.data;
            this.refreshTasks();
        }
    }


    refreshTasks() {
        refreshApex(this.wiredTasks);
    }


    handleComboboxFocus() {
        this.isComboboxFocused = true;
    }


    handleComboboxBlur() {
        if (!this.isComboboxFocused) {
            this.selectedSubject = '--None--';
        }
    }

    handleviewMore() {
        this.recordViewStatus = false
        if(this.selectedSubject !== '--None--'){                
            this.filteredTasks = this.allTasks.filter(task => task.Subject === this.selectedSubject);
           
        }
        else{
            this.filteredTasks = this.allTasks; // Show all tasks without slicing
        }
    }

    handleviewLess() {
        this.recordViewStatus = true
        this.filteredTasks = this.filteredTasks.slice(0, 10); // Show only 10 tasks
    }

    handleSubjectChange(event) {
        this.selectedSubject = event.detail.value;
      }


}