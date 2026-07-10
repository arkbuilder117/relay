import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  copy() {
    navigator.clipboard.writeText(this.urlValue).then(() => {
      const original = this.element.textContent.trim()
      this.element.textContent = "Copied!"
      setTimeout(() => this.element.textContent = original, 2000)
    })
  }
}
