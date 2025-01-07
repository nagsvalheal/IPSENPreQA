import { LightningElement, api, track, wire } from "lwc";
import { subscribe, unsubscribe } from "lightning/empApi";
import getTimelineMap from "@salesforce/apex/J_TimelineController.getTimelineMap";
import J_EnableTimeline from "@salesforce/label/c.J_EnableTimeline"; // Import custom label
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

export default class TimelineProgress extends LightningElement {
  @api recordId;
  @track stages = [];
  @track isEnabled = false; // Track to control visibility

  wiredTimelineResponse;
  subscription = null;

  // Initialize component and set visibility based on the custom label
  connectedCallback() {
    this.isEnabled = J_EnableTimeline === "true"; // Set true if the custom label is 'true'
    if (this.isEnabled) {
      this.subscribeToPlatformEvent();
    }
  }

  // Unsubscribe on disconnect
  disconnectedCallback() {
    this.unsubscribeFromPlatformEvent();
  }

  // Wire the Apex method to fetch timeline data
  @wire(getTimelineMap, { enrolleeId: "$recordId" })
  wiredTimeline(result) {
    this.wiredTimelineResponse = result;
    if (result.data) {
      this.processTimelineData(result.data);
    } else if (result.error) {
      this.showToast(
        "Error",
        "There was an error fetching timeline data: " + result.error,
        "error"
      );
    }
  }

  // Subscribe to the platform event
  subscribeToPlatformEvent() {
    const channel = `/event/TimelineUpdateEvent__e`;
    const callback = (event) => {
      const eventData = event.data.payload;
      if (eventData.Enrollee_Id__c === this.recordId) {
        this.refreshTimelineData();
      }
    };
    subscribe(channel, -1, callback).then((response) => {
      this.subscription = response;
    });
  }

  // Unsubscribe from the platform event
  unsubscribeFromPlatformEvent() {
    if (this.subscription) {
      unsubscribe(this.subscription);
      this.subscription = null;
    }
  }

  // Refresh timeline data
  refreshTimelineData() {
    refreshApex(this.wiredTimelineResponse);
  }

  // Process timeline data for rendering
  processTimelineData(data) {
    this.stages = Object.keys(data)
      .filter((key) => data[key] > 0)
      .map((key) => ({
        name: key,
        value: data[key]
      }));
  }

  // Show toast notification
  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }
}