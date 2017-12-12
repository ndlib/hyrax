module Hyrax
  module ManifestComponents
    delegate :rendering_ids, to: :solr_document

    def manifest_url
      manifest_helper.polymorphic_url([:manifest, self])
    end

    # IIIF rendering linking property for inclusion in the manifest
    #
    # @return [Array] array of rendering hashes
    def sequence_rendering
      renderings = []
      if solr_document.rendering_ids.present?
        solr_document.rendering_ids.each do |file_set_id|
          renderings << build_rendering(file_set_id)
        end
      end
      renderings.flatten
    end

    # IIIF metadata for inclusion in the manifest
    #
    # @return [Array] array of metadata hashes
    def manifest_metadata
      metadata = []
      metadata_fields.each do |field|
        metadata << {
          'label' => I18n.t("simple_form.labels.defaults.#{field}"),
          'value' => wrapped_metadata_values(field)
        }
      end
      metadata
    end

    private

      def manifest_helper
        @manifest_helper ||= ManifestHelper.new(request.base_url)
      end

      # Build a rendering hash
      #
      # @return [Hash] rendering
      def build_rendering(file_set_id)
        file_set_document = query_for_rendering(file_set_id).first # only one result is returned
        label = file_set_document['label_ssi'] ? ": #{file_set_document['label_ssi']}" : ''
        {
          '@id' => Hyrax::Engine.routes.url_helpers.download_url(file_set_document[ActiveFedora.id_field], host: request.host),
          'format' => file_set_document.fetch('mime_type_ssi', I18n.t("hyrax.manifest.unknown_mime_text")),
          'label' => I18n.t("hyrax.manifest.download_text") + label
        }
      end

      # Query for the properties to create a rendering
      #
      # @return [SolrResult] query result
      def query_for_rendering(file_set_id)
        ActiveFedora::SolrService.query("id:#{file_set_id}",
                                        fl: [ActiveFedora.id_field, 'label_ssi', 'mime_type_ssi'],
                                        rows: 1)
      end

      # Retrieve the manifest metadata fields
      #
      # @return [Array] fields
      def metadata_fields
        Hyrax.config.iiif_metadata_fields
      end

      # Get the metadata value(s).
      #
      # @return [Array] field value(s)
      def wrapped_metadata_values(field)
        Array.wrap(send(field))
      end
  end
end
