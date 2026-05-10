# ==============================================================================
#  LAYOUT AUTO-SCALE LABELER
#  Loader d'extension SketchUp -- enregistre l'extension dans le
#  gestionnaire et delegue le chargement reel au fichier main (rb ou rbe).
#
#  Auteur     : Jacques Vernet
#  Copyright  : (c) Jacques Vernet
# ==============================================================================

require 'sketchup.rb'
require 'extensions.rb'

module JVernet
  module LayoutScaleLabeler

    VERSION   = '1.0.0'.freeze
    TITLE     = 'LayOut Auto-Scale Labeler'.freeze
    CREATOR   = 'Jacques Vernet'.freeze
    COPYRIGHT = "(c) #{Time.now.year} Jacques Vernet".freeze

    # Chemins exposes (le loader reste en .rb clair, donc __FILE__ est fiable ici)
    PLUGIN_ROOT = File.dirname(__FILE__).freeze
    PLUGIN_DIR  = File.join(PLUGIN_ROOT, 'jvernet_layout_scale_labeler').freeze

    unless file_loaded?(__FILE__)
      # IMPORTANT : pas d'extension dans le chemin du loader.
      # Sketchup cherchera main.rbe (chiffre) puis main.rb (clair).
      loader = File.join(PLUGIN_DIR, 'main')

      # Pour la description du gestionnaire d'extensions, on choisit la langue
      # en fonction du locale courant (FR si Sketchup.get_locale commence par "fr",
      # EN sinon). C'est juste un texte d'info, l'i18n complete est dans main.
      desc_fr = "Annote automatiquement les viewports d'un fichier LayOut " \
                "avec leur echelle (1/50, 1/100, etc.) et, en option, le nom " \
                "de la scene SketchUp. Necessite SketchUp Pro 2018+."
      desc_en = "Automatically annotates LayOut viewports with their scale " \
                "(1/50, 1/100, etc.) and optionally the associated SketchUp " \
                "scene name. Requires SketchUp Pro 2018+."
      description = (Sketchup.get_locale.to_s.downcase.start_with?("fr") ? desc_fr : desc_en)

      ex = SketchupExtension.new(TITLE, loader)
      ex.version     = VERSION
      ex.creator     = CREATOR
      ex.copyright   = COPYRIGHT
      ex.description = description

      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end
end
