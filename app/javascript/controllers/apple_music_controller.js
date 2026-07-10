import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "form", "tokenField"]
  static values  = { developerToken: String }

  async authorize() {
    this.buttonTarget.textContent = "Connecting..."
    this.buttonTarget.disabled = true
    try {
      await MusicKit.configure({
        developerToken: this.developerTokenValue,
        app: { name: "StreamShift", build: "1.0" }
      })
      const music     = MusicKit.getInstance()
      const userToken = await music.authorize()
      this.tokenFieldTarget.value = userToken
      this.formTarget.requestSubmit()
    } catch (err) {
      this.buttonTarget.textContent = "Connect Apple Music"
      this.buttonTarget.disabled = false
    }
  }
}
