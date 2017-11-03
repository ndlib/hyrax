export default class {
  constructor(element) {
    this.element = element
  }

  setup() {
    // Watch for changes to "sharable" checkbox
    this.sharableInput = this.element.find("input[type='checkbox'][name$='[sharable]']")
    $(this.sharableInput).on('change', () => { this.sharableChanged() })
    this.sharableChanged()
  }

  // Based on the "sharable" checked/unchecked, enable/disable adjust share_applies_to_new_works checkbox
  sharableChanged() {
    this.sharableInput = this.element.find("input[type='checkbox'][name$='[sharable]']")
    let selected = this.sharableInput.is(':checked')
    let disabled = this.sharableInput.is(':disabled')

    this.shareAppliesToWorkInput = this.element.find("input[type='checkbox'][name$='[share_applies_to_new_works]']")
    if(selected) {
        // if sharable is selected, then base disabled on whether or not sharable is disabled.  It will be disabled when a
        // collection of this type exists.  In that case, share_applies_to_new_works is readonly, that is, it has the value
        // from the database and is disabled
        this.shareAppliesToWorkInput.prop("disabled", disabled)
        if(disabled) {
            this.addDisabledClasses(this.shareAppliesToWorkInput)
        }
        else {
            this.removeDisabledClasses(this.shareAppliesToWorkInput)
        }
    }
    else {
        // if sharable is not selected, then share_applies_to_enw_works must be unchecked and disabled so it cannot be changed
        this.shareAppliesToWorkInput.prop("checked", false)
        this.shareAppliesToWorkInput.prop("disabled", true)
        this.addDisabledClasses(this.shareAppliesToWorkInput)
    }
  }

  /**
   * Add disabled class to elements surrounding the APPLIES TO NEW WORKS checkbox when it is disabled
   * @param {Object} shareAppliesToWorkInput - checkbox element for APPLIES TO NEW WORKS
   */
  addDisabledClasses(shareAppliesToWorkInput) {
      shareAppliesToWorkInput.addClass("disabled")
      shareAppliesToWorkInput.closest('input').addClass("disabled")
      shareAppliesToWorkInput.closest('label').addClass("disabled")
      shareAppliesToWorkInput.closest('div').addClass("disabled")
  }

    /**
     * Remove disabled class from elements surrounding the APPLIES TO NEW WORKS checkbox when it is not disabled
     * @param {Object} shareAppliesToWorkInput - checkbox element for APPLIES TO NEW WORKS
     */
  removeDisabledClasses(shareAppliesToWorkInput) {
      shareAppliesToWorkInput.removeClass("disabled")
      shareAppliesToWorkInput.closest('input').removeClass("disabled")
      shareAppliesToWorkInput.closest('label').removeClass("disabled")
      shareAppliesToWorkInput.closest('div').removeClass("disabled")
  }
}
