import { LightningElement, api, wire } from 'lwc';
import getContentById from '@salesforce/apex/ContentSelector.getContentById';
import posterImg from '@salesforce/resourceUrl/moviePoster';
import { NavigationMixin } from 'lightning/navigation';

export default class ContentPoster extends NavigationMixin(LightningElement) {

    @api recordId; // Salesforce inyecta automáticamente el Id del registro de la Record Page
    @api content;

    @wire(getContentById, { contentId: '$recordId' })
    wiredContent({ error, data }) {
        if (data) {
            this.content = data;
        } else if (error) {
            console.error('Error fetching content:', error);
        }
    }

    get hasContent() {
        return this.content !== undefined && this.content !== null;
    }
    handleClick() {
        console.log('Navigating to:', this.content.Id);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.content.Id,
                objectApiName: 'Content__c',
                actionName: 'view'
            }
        });
    }

    get posterUrl() {
        // aquí puedes usar el valor de content.Movie_poster_url__c si quieres múltiples imágenes
        // o simplemente usar el static resource importado
        return posterImg; 
    }
}