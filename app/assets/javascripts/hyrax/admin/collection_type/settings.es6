// Enable/disable sharing APPLIES_TO_NEW_WORKS checkbox based on the state of checkbox SHARABLE
export default class {
  constructor(element) {
    this.element = element
  }

  setup() {
    // Watch for changes to "sharable" checkbox
    $("#collection_type_sharable").on('change', () => { this.sharableChanged() })
    this.sharableChanged()
  }

  // Based on the "sharable" checked/unchecked, enable/disable adjust share_applies_to_new_works checkbox
  sharableChanged() {
    let selected = $("#collection_type_sharable").is(':checked')
    let disabled = $("#collection_type_sharable").is(':disabled')

    if(selected) {
        // if sharable is selected, then base disabled on whether or not sharable is disabled.  It will be disabled when a
        // collection of this type exists.  In that case, share_applies_to_new_works is readonly, that is, it has the value
        // from the database and is disabled
        $("#collection_type_share_applies_to_new_works").prop("disabled", disabled)
        if(disabled) {
            this.addDisabledClasses()
        }
        else {
            this.removeDisabledClasses()
        }
    }
    else {
        // if sharable is not selected, then share_applies_to_enw_works must be unchecked and disabled so it cannot be changed
        $("#collection_type_share_applies_to_new_works").prop("checked", false)
        $("#collection_type_share_applies_to_new_works").prop("disabled", true)
        this.addDisabledClasses()
    }
  }

  /**
   * Add disabled class to elements surrounding the APPLIES TO NEW WORKS checkbox when it is disabled
   */
  addDisabledClasses() {
      $("#sharable-applies-to-new-works-setting-checkbox-container").addClass("disabled")
      $("#sharable-applies-to-new-works-setting-label").addClass("disabled")
      $("#collection_type_share_applies_to_new_works").addClass("disabled")
  }

    /**
     * Remove disabled class from elements surrounding the APPLIES TO NEW WORKS checkbox when it is not disabled
     */
  removeDisabledClasses() {
      $("#sharable-applies-to-new-works-setting-checkbox-container").removeClass("disabled")
      $("#sharable-applies-to-new-works-setting-label").removeClass("disabled")
      $("#collection_type_share_applies_to_new_works").removeClass("disabled")
  }
}
