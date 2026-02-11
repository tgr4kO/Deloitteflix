import { LightningElement, api, wire } from 'lwc';
import getContentById from '@salesforce/apex/ContentSelector.getContentById';
import { NavigationMixin } from 'lightning/navigation';

export default class ContentPoster extends NavigationMixin(LightningElement) {
    @api recordId;   // SOLO se usa cuando el componente está solo en la Record Page
    @api content;    // Se usa cuando viene dentro de la galería

    // Si el padre NO pasa `content`, lo traemos por recordId (modo record page)
    @wire(getContentById, { contentId: '$recordId' })
    wiredContent({ error, data }) {
        if (data && !this.content) {
            // Solo machacamos si el padre no ha pasado nada
            this.content = data;
        } else if (error) {
            // Puedes loguear si hace falta
            // eslint-disable-next-line no-console
            console.error('Error fetching content:', error);
        }
    }

    get hasContent() {
        return !!this.content;
    }

    handleClick() {
        if (!this.content) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.content.Id,
                objectApiName: 'Content__c',
                actionName: 'view'
            }
        });
    }
}