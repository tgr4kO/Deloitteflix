import { LightningElement, api } from 'lwc';

export default class Omdb_table extends LightningElement {
    @api results = [];

    get hasResults() {
        return this.results && this.results.length > 0;
    }

    handleDetail(event) {
        const imdbId = event.currentTarget.dataset.id;
        this.dispatchEvent(
            new CustomEvent('detail', {
                detail: { imdbId }
            })
        );
    }

    handleDownload(event) {
        const imdbId = event.currentTarget.dataset.id;
        this.dispatchEvent(
            new CustomEvent('download', {
                detail: { imdbId }
            })
        );
    }
}