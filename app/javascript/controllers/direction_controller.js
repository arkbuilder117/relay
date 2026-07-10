import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "input", "submit"]

  select(event) {
    this.cardTargets.forEach(card => card.classList.remove("border-indigo-500", "bg-indigo-50"))
    event.currentTarget.classList.add("border-indigo-500", "bg-indigo-50")
    this.inputTarget.value = event.currentTarget.dataset.value
    this.submitTarget.disabled = false
  }
}
