import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit", "card", "likedSongs", "toggleAll"]

  toggleAll() {
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    const selectingAll = checked === 0
    this.checkboxTargets.forEach(cb => cb.checked = selectingAll ? true : false)
    this.updateState()
  }

  updateState() {
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    const total   = this.checkboxTargets.length
    const likedSongsOn = this.hasLikedSongsTarget && this.likedSongsTarget.checked

    if (checked === 0) {
      this.toggleAllTarget.textContent = "Select all"
    } else if (checked === total) {
      this.toggleAllTarget.textContent = "Deselect all"
    } else {
      this.toggleAllTarget.textContent = `Deselect (${checked})`
    }

    this.submitTarget.disabled = (checked === 0 && !likedSongsOn)

    this.checkboxTargets.forEach(cb => {
      cb.closest("[data-playlist-target='card']").classList.toggle("selected", cb.checked)
    })
  }
}
