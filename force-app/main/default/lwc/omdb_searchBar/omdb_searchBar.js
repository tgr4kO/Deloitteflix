import { LightningElement } from 'lwc';

export default class Omdb_searchBar extends LightningElement {
    searchText = '';
    timeoutId;

    get showHelper() {
        return this.searchText && this.searchText.length < 5;
    }

    handleChange(event) {
        this.searchText = event.target.value;
    }

    handleKeyUp(event) {
        this.searchText = event.target.value;

        // Pequeño debounce para no spamear al padre
        window.clearTimeout(this.timeoutId);
        this.timeoutId = window.setTimeout(() => {
            this.dispatchSearchIfLongEnough();
        }, 400);
    }

    dispatchSearchIfLongEnough() {
        if (this.searchText && this.searchText.length >= 5) {
            this.dispatchEvent(
                new CustomEvent('searchchange', {
                    detail: { query: this.searchText }
                })
            );
        }
    }
}