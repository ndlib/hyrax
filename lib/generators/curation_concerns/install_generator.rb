require 'rails/generators'

module CurationConcerns
  class Install < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    argument :model_name, type: :string , default: "user"
    desc """
  This generator makes the following changes to your application:
   1. Runs installers for blacklight & hydra-head (which also install & configure devise)
   2. Runs curation_concerns:models:install
   3. Injects CurationConcerns routes
   4. Adds CurationConcerns abilities into the Ability class
   5. Adds controller behavior to the application controller
   6. Copies the catalog controller into the local app
   7. Adds CurationConcerns::SolrDocumentBehavior to app/models/solr_document.rb
         """

    def run_required_generators
      say_status("warning", "[CurationConcerns] GENERATING BLACKLIGHT", :yellow)
      generate "blacklight:install --devise"
      say_status("warning", "[CurationConcerns] GENERATING HYDRA-HEAD", :yellow)
      generate "hydra:head -f"
      say_status("warning", "[CurationConcerns] GENERATING CURATION_CONCERNS MODELS", :yellow)
      generate "curation_concerns:models:install#{options[:force] ? ' -f' : ''}"
    end

    def remove_catalog_controller
      say_status("warning", "Removing Blacklight's generated CatalogController...", :yellow)
      remove_file('app/controllers/catalog_controller.rb')
    end

    def inject_application_controller_behavior
      inject_into_file 'app/controllers/application_controller.rb', :after => /Blacklight::Controller\s*\n/ do
        "\n  # Adds CurationConcerns behaviors to the application controller.\n" +
        "  include CurationConcerns::ApplicationControllerBehavior\n"
      end
    end

    def replace_blacklight_layout
      gsub_file 'app/controllers/application_controller.rb', /layout 'blacklight'/,
        "include CurationConcerns::ThemedLayoutController\n  with_themed_layout '1_column'\n"
    end

    # def insert_builder
    #   insert_into_file 'app/models/search_builder.rb', after: /include Blacklight::Solr::SearchBuilderBehavior/ do
    #     # First line should be generated by Hydra. projecthydra/hydra-head#255
    #     "\n  include Hydra::AccessControlsEnforcement" +
    #     "\n  include CurationConcerns::SearchBuilder\n"
    #   end
    # end

    def remove_blacklight_scss
      remove_file 'app/assets/stylesheets/blacklight.css.scss'
    end

    # END Blacklight stuff

    def inject_routes
      inject_into_file 'config/routes.rb', :after => /devise_for :users\s*\n/ do
        "  mount Hydra::Collections::Engine => '/'\n"\
        "  mount CurationConcerns::Engine, at: '/'\n"\
        "  curation_concerns_collections\n"\
        "  curation_concerns_basic_routes\n"\
        "  curation_concerns_embargo_management\n"\
      end
    end

    def inject_ability
      inject_into_file 'app/models/ability.rb', :after => /Hydra::Ability\s*\n/ do
        "  include CurationConcerns::Ability\n"\
        "  self.ability_logic += [:everyone_can_create_curation_concerns]\n\n"
      end
    end

    # Add behaviors to the SolrDocument model
    def inject_solr_document_behavior
      file_path = "app/models/solr_document.rb"
      if File.exists?(file_path)
        inject_into_file file_path, after: /include Blacklight::Solr::Document.*$/ do
          "\n  # Adds CurationConcerns behaviors to the SolrDocument.\n" +
            "  include CurationConcerns::SolrDocumentBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  CurationConcerns requires a SolrDocument object. This generators assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def assets
      copy_file "curation_concerns.css.scss", "app/assets/stylesheets/curation_concerns.css.scss"
      copy_file "curation_concerns.js", "app/assets/javascripts/curation_concerns.js"
    end

    def add_helper
      copy_file "curation_concerns_helper.rb", "app/helpers/curation_concerns_helper.rb"
    end

    def add_config_file
      copy_file "curation_concerns_config.rb", "config/initializers/curation_concerns_config.rb"
    end
  end
end
