import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date"]

  reload() {
    const date = this.dateTarget.value
    if (date) {
      window.location.href = `${window.location.pathname}?date=${date}`
    }
  }
}
