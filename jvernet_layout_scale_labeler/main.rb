# ==============================================================================
#  LAYOUT AUTO-SCALE LABELER (V1.0)
#
#  Annote automatiquement les viewports d'un document LayOut avec leur echelle.
#  - Ouverture / sauvegarde via Layout::Document.open / save
#  - Detecte les Layout::SketchUpModel non perspective et calcule viewport.scale
#  - Place une etiquette FormattedText parametrable sur un calque dedie
#  - Fournit un HtmlDialog pour les reglages utilisateur
#
#  Auteur    : Jacques Vernet
#  Copyright : (c) Jacques Vernet
# ==============================================================================

require 'json'

module JVernet
  module LayoutScaleLabeler

    PREF_KEY     = "JVernet_LayoutScaleLabeler".freeze
    LAYER_NAME   = "Auto_Scales".freeze

    # ============================================================
    #  I18n -- dictionnaire de traductions
    #  Ajout d'une langue : ajouter une cle ISO ("es", "de", ...)
    #  dans TRANSLATIONS avec les memes cles que :en.
    #  Toute cle manquante retombera automatiquement sur :en.
    # ============================================================
    module I18n

      DEFAULT_LOCALE = :en

      TRANSLATIONS = {
        :en => {
          # Extension metadata
          "ext.title"           => "LayOut Auto-Scale Labeler",
          "ext.description"     => "Automatically annotates LayOut viewports with their scale and optional SketchUp scene name. Requires LayOut 2018+.",

          # Menu / toolbar
          "menu.command"        => "LayOut Auto-Scale",
          "menu.tooltip"        => "Annotate scales of a LayOut file",
          "menu.statusbar"      => "Automatic scale annotation of viewports in a .layout file",
          "toolbar.name"        => "LayOut Scale Labeler",

          # Dialog
          "dialog.title"        => "LayOut Auto-Scale Labeler",
          "dialog.heading"      => "LayOut Auto-Scale Labeler",
          "dialog.text"         => "Text",
          "dialog.format"       => "Format (available variables: <code>@scale</code>, <code>@scene</code>)",
          "dialog.format.help"  => "Ex: \u00ab Scale: @scale \u00bb gives \u00ab Scale: 1/50 \u00bb. You can also insert <code>@scene</code> for the SketchUp scene name.",
          "dialog.scale_unit"   => "Scale unit",
          "dialog.scale.ratio"  => "Ratio (1/50)",
          "dialog.scale.decimal"=> "Decimal (0.02)",
          "dialog.persp_text"   => "Text for perspective views",
          "dialog.typo"         => "Typography",
          "dialog.font"         => "Font",
          "dialog.size"         => "Size (pts)",
          "dialog.position"     => "Positioning",
          "dialog.anchor"       => "Anchor",
          "dialog.anchor.below" => "Below the viewport",
          "dialog.anchor.over"  => "Above the viewport",
          "dialog.offset"       => "Offset (mm)",
          "dialog.options"      => "Options",
          "dialog.ignore_persp" => "Ignore perspective views",
          "dialog.show_scene"   => "Show scene name before scale",
          "dialog.show_scene.h" => "Result: \u00ab South View \u2014 Scale: 1/50 \u00bb. Ignored if format already contains <code>@scene</code>.",
          "dialog.language"     => "Language",
          "dialog.lang.auto"    => "Auto (SketchUp)",
          "dialog.lang.fr"      => "Fran\u00e7ais",
          "dialog.lang.en"      => "English",
          "dialog.btn.cancel"   => "Cancel",
          "dialog.btn.save"     => "Save settings",
          "dialog.btn.run"      => "Select and Process...",

          # Default format string
          "default.format"      => "Scale: @scale",
          "default.persp_text"  => "NTS",

          # Runtime messages
          "msg.no_layout_api"   => "The LayOut Ruby API is not available.\nThis feature requires SketchUp Pro 2018 or newer.",
          "msg.choose_input"    => "Select a LayOut file",
          "msg.save_question"   => "Processing complete.\n\nSave INTO the original file?\n(Yes = overwrite, No = save a copy, Cancel = do not save)",
          "msg.save_copy"       => "Save copy",
          "msg.copy_suffix"     => "_scales",
          "msg.file_not_found"  => "File not found:\n%s",
          "msg.cant_open"       => "Cannot open file:\n%s\n\n%s\n\nMake sure it is not already open in LayOut.",
          "msg.open_error"      => "Open error:\n%s",
          "msg.process_error"   => "Error during processing:\n%s\n\n%s",
          "msg.no_views"        => "No SketchUp views were found in this document.",
          "msg.no_save"         => "Cancelled: no save performed.",
          "msg.cant_save"       => "Cannot save:\n%s\n\n%s\n\nThe file may be locked (open in LayOut?).",
          "msg.save_error"      => "Save error:\n%s",
          "msg.summary"         => "Done.\n\nTotal views: %{total}\nLabelled scales: %{labeled}\nPerspective views: %{perspective}\nIgnored views: %{skipped}\nPages affected: %{pages}\n\nFile: %{path}"
        },

        :fr => {
          "ext.title"           => "LayOut Auto-Scale Labeler",
          "ext.description"     => "Annote automatiquement les viewports d'un fichier LayOut avec leur echelle et, en option, le nom de la scene SketchUp. Necessite LayOut 2018+.",

          "menu.command"        => "LayOut Auto-Scale",
          "menu.tooltip"        => "Annoter les echelles d'un fichier LayOut",
          "menu.statusbar"      => "Annotation automatique des viewports d'un fichier .layout",
          "toolbar.name"        => "LayOut Scale Labeler",

          "dialog.title"        => "LayOut Auto-Scale Labeler",
          "dialog.heading"      => "LayOut Auto-Scale Labeler",
          "dialog.text"         => "Texte",
          "dialog.format"       => "Format (variables disponibles : <code>@scale</code>, <code>@scene</code>)",
          "dialog.format.help"  => "Ex : \u00ab Echelle : @scale \u00bb donnera \u00ab Echelle : 1/50 \u00bb. Vous pouvez aussi inserer <code>@scene</code> pour le nom de la scene SketchUp.",
          "dialog.scale_unit"   => "Unite d'echelle",
          "dialog.scale.ratio"  => "Ratio (1/50)",
          "dialog.scale.decimal"=> "Decimal (0.02)",
          "dialog.persp_text"   => "Texte des vues perspective",
          "dialog.typo"         => "Typographie",
          "dialog.font"         => "Police",
          "dialog.size"         => "Taille (pts)",
          "dialog.position"     => "Positionnement",
          "dialog.anchor"       => "Ancrage",
          "dialog.anchor.below" => "Sous le viewport",
          "dialog.anchor.over"  => "Sur (au-dessus du) viewport",
          "dialog.offset"       => "Offset (mm)",
          "dialog.options"      => "Options",
          "dialog.ignore_persp" => "Ignorer les vues en perspective",
          "dialog.show_scene"   => "Afficher le nom de la scene avant l'echelle",
          "dialog.show_scene.h" => "Resultat : \u00ab Vue Sud \u2014 Echelle : 1/50 \u00bb. Ignore si le format contient deja <code>@scene</code>.",
          "dialog.language"     => "Langue",
          "dialog.lang.auto"    => "Auto (SketchUp)",
          "dialog.lang.fr"      => "Fran\u00e7ais",
          "dialog.lang.en"      => "English",
          "dialog.btn.cancel"   => "Annuler",
          "dialog.btn.save"     => "Enregistrer reglages",
          "dialog.btn.run"      => "Selectionner et Traiter...",

          "default.format"      => "Echelle : @scale",
          "default.persp_text"  => "NTS",

          "msg.no_layout_api"   => "L'API LayOut Ruby n'est pas disponible.\nCette fonction necessite SketchUp Pro 2018 ou plus recent.",
          "msg.choose_input"    => "Selectionnez un fichier LayOut",
          "msg.save_question"   => "Le traitement est termine.\n\nEnregistrer DANS le fichier d'origine ?\n(Oui = ecraser, Non = enregistrer une copie, Annuler = ne rien sauvegarder)",
          "msg.save_copy"       => "Enregistrer la copie",
          "msg.copy_suffix"     => "_scales",
          "msg.file_not_found"  => "Fichier introuvable :\n%s",
          "msg.cant_open"       => "Impossible d'ouvrir le fichier :\n%s\n\n%s\n\nVerifiez qu'il n'est pas deja ouvert dans LayOut.",
          "msg.open_error"      => "Erreur d'ouverture :\n%s",
          "msg.process_error"   => "Erreur pendant le traitement :\n%s\n\n%s",
          "msg.no_views"        => "Aucune vue SketchUp n'a ete trouvee dans ce document.",
          "msg.no_save"         => "Annulation : aucune sauvegarde effectuee.",
          "msg.cant_save"       => "Impossible d'enregistrer :\n%s\n\n%s\n\nLe fichier est peut-etre verrouille (ouvert dans LayOut ?).",
          "msg.save_error"      => "Erreur d'enregistrement :\n%s",
          "msg.summary"         => "Termine.\n\nVues totales : %{total}\nEchelles annotees : %{labeled}\nVues perspective : %{perspective}\nVues ignorees : %{skipped}\nPages concernees : %{pages}\n\nFichier : %{path}"
        }
      }.freeze

      @current_locale = nil

      # Detecte la langue effective.
      # - Si l'utilisateur a force une langue ("fr" ou "en"), on l'utilise.
      # - Sinon on lit Sketchup.get_locale et on prend les 2 premiers caracteres.
      # - Fallback sur DEFAULT_LOCALE.
      def self.detect_locale(user_choice = "auto")
        if user_choice && user_choice != "auto"
          sym = user_choice.to_s.downcase.to_sym
          return sym if TRANSLATIONS.key?(sym)
        end
        begin
          loc = Sketchup.get_locale.to_s.downcase
          short = loc.split(/[-_]/).first
          sym = short.to_sym
          return sym if TRANSLATIONS.key?(sym)
        rescue StandardError
        end
        DEFAULT_LOCALE
      end

      def self.set_locale(locale_sym)
        @current_locale = locale_sym
      end

      def self.current_locale
        @current_locale || DEFAULT_LOCALE
      end

      # Recupere une chaine traduite. Si la cle manque dans la locale
      # courante, on retombe sur l'anglais. Si elle manque aussi en
      # anglais, on retourne la cle elle-meme (visible pour debug).
      def self.t(key)
        loc = current_locale
        TRANSLATIONS.dig(loc, key) ||
          TRANSLATIONS.dig(DEFAULT_LOCALE, key) ||
          key.to_s
      end

      # Renvoie le dictionnaire complet de la locale courante,
      # utile pour injecter toutes les chaines au HtmlDialog en JS.
      def self.dict
        TRANSLATIONS[current_locale] || TRANSLATIONS[DEFAULT_LOCALE]
      end
    end

    # Raccourci local
    def self.t(key); I18n.t(key); end

    # DIALOG_TITLE est calcule dynamiquement via I18n.t("dialog.title")
    # On ne le fige plus en constante.

    DEFAULT_CONFIG = {
      "format"             => nil,             # nil = utilise default.format selon locale
      "font_family"        => "Arial",
      "font_size"          => 10,
      "anchor"             => "below",         # "below" | "over"
      "offset_mm"          => 5.0,
      "ignore_perspective" => false,
      "perspective_text"   => nil,             # nil = utilise default.persp_text selon locale
      "scale_unit"         => "ratio",         # "ratio" | "decimal"
      "show_scene"         => false,           # prefixe le nom de scene SketchUp
      "language"           => "auto"           # "auto" | "fr" | "en"
    }.freeze

    @config = nil
    @dialog = nil

    # ------------------------------------------------------------
    # Preferences
    # ------------------------------------------------------------
    def self.config
      return @config if @config
      @config = DEFAULT_CONFIG.dup
      DEFAULT_CONFIG.each_key do |k|
        v = Sketchup.read_default(PREF_KEY, k, nil)
        @config[k] = v unless v.nil?
      end
      # Applique la langue choisie a I18n
      I18n.set_locale(I18n.detect_locale(@config["language"]))
      # Resout les valeurs nil par leur traduction par defaut
      @config["format"]           ||= I18n.t("default.format")
      @config["perspective_text"] ||= I18n.t("default.persp_text")
      @config
    end

    def self.save_config(new_cfg)
      cfg = config
      DEFAULT_CONFIG.each_key do |k|
        next unless new_cfg.key?(k)
        cfg[k] = new_cfg[k]
        Sketchup.write_default(PREF_KEY, k, new_cfg[k])
      end
      cfg
    end

    # ------------------------------------------------------------
    # Conversion echelle decimale -> texte
    # 0.02 -> "1/50"  ;  50.0 -> "50/1"  ;  1.0 -> "1/1"
    # ------------------------------------------------------------
    def self.format_scale_value(scale_value, mode = "ratio")
      return nil if scale_value.nil?
      sv = scale_value.to_f
      return nil if sv <= 0
      if mode == "decimal"
        return sprintf("%.4f", sv).sub(/0+$/, "").sub(/\.$/, "")
      end
      if sv < 1.0
        denom = (1.0 / sv).round
        "1/#{denom}"
      elsif sv > 1.0
        "#{sv.round}/1"
      else
        "1/1"
      end
    end

    def self.build_label_text(scale_value, cfg, perspective: false, scene_name: nil)
      base =
        if perspective || scale_value.nil?
          cfg["perspective_text"].to_s
        else
          token = format_scale_value(scale_value, cfg["scale_unit"])
          cfg["format"].to_s.gsub("@scale", token.to_s)
        end

      # Substitution de la variable @scene si l'utilisateur l'a mise dans le format.
      scene_str = scene_name.to_s.strip
      base = base.gsub("@scene", scene_str)

      # Prefixe automatique si l'option est cochee ET que @scene n'a pas
      # deja ete utilise explicitement dans le format ET qu'une scene existe.
      if cfg["show_scene"] && !scene_str.empty? && !cfg["format"].to_s.include?("@scene")
        base = "#{scene_str} \u2014 #{base}"
      end

      base
    end

    # ------------------------------------------------------------
    # Acces / creation du calque dedie
    # ------------------------------------------------------------
    def self.find_or_create_layer(doc)
      doc.layers.each do |lay|
        return lay if lay.name == LAYER_NAME
      end
      doc.layers.add(LAYER_NAME)
    end

    # ------------------------------------------------------------
    # Iteration unifiee sur toutes les entites du document.
    # L'API LayOut expose : doc.shared_entities (calques partages)
    # et page.nonshared_entities (par page). Pas de doc.entities.
    # ------------------------------------------------------------
    def self.each_entity(doc)
      return enum_for(:each_entity, doc) unless block_given?
      begin
        if doc.respond_to?(:shared_entities)
          doc.shared_entities.each { |e| yield e, nil }
        end
      rescue StandardError
      end
      begin
        doc.pages.each do |page|
          begin
            ents = page.respond_to?(:nonshared_entities) ? page.nonshared_entities : nil
            ents ||= page.respond_to?(:entities) ? page.entities : nil
            next unless ents
            ents.each { |e| yield e, page }
          rescue StandardError
            next
          end
        end
      rescue StandardError
      end
    end

    def self.entity_on_layer?(entity, layer)
      li = entity.layer_instance rescue nil
      return false unless li
      definition = li.respond_to?(:definition) ? li.definition : li
      return true if definition == layer
      return true if definition.respond_to?(:name) && definition.name == LAYER_NAME
      false
    end

    # ------------------------------------------------------------
    # Suppression des entites residuelles sur le calque dedie
    # ------------------------------------------------------------
    def self.purge_layer(doc, layer)
      removed = 0
      to_remove = []
      each_entity(doc) do |e, _page|
        begin
          to_remove << e if entity_on_layer?(e, layer)
        rescue StandardError
          next
        end
      end
      to_remove.each do |e|
        begin
          doc.remove_entity(e)
          removed += 1
        rescue StandardError
          next
        end
      end
      removed
    end

    # ------------------------------------------------------------
    # Recuperation du Layout::SketchUpModel : echelle + bbox + page + scene
    # ------------------------------------------------------------
    def self.viewport_info(viewport)
      info = { :scale => nil, :orthogonal => true, :bounds => nil, :page => nil, :scene => nil }
      begin
        if viewport.respond_to?(:perspective?)
          info[:orthogonal] = !viewport.perspective?
        elsif viewport.respond_to?(:orthogonal?)
          info[:orthogonal] = viewport.orthogonal?
        end
      rescue StandardError
        info[:orthogonal] = true
      end
      begin
        info[:scale] = viewport.respond_to?(:scale) ? viewport.scale : nil
      rescue StandardError
        info[:scale] = nil
      end
      begin
        info[:bounds] = viewport.bounds if viewport.respond_to?(:bounds)
      rescue StandardError
        info[:bounds] = nil
      end
      begin
        li = viewport.layer_instance
        info[:page] = li.page if li.respond_to?(:page)
      rescue StandardError
        info[:page] = nil
      end
      info[:scene] = scene_name_for(viewport)
      info
    end

    # ------------------------------------------------------------
    # Recupere le nom de la scene SketchUp associee au viewport.
    # API officielle Layout::SketchUpModel :
    #   - #current_scene : retourne un index entier
    #   - #scenes        : retourne un tableau de noms (le 1er = "Last saved SketchUp View")
    # On recupere donc scenes[current_scene]. Retourne nil en cas d'echec.
    # ------------------------------------------------------------
    def self.scene_name_for(viewport)
      return nil unless viewport.respond_to?(:current_scene) && viewport.respond_to?(:scenes)
      begin
        idx = viewport.current_scene
        return nil unless idx.is_a?(Integer)
        list = viewport.scenes
        return nil unless list.respond_to?(:[])
        name = list[idx]
        return nil if name.nil?
        s = name.to_s.strip
        return nil if s.empty?
        s
      rescue StandardError
        nil
      end
    end

    # ------------------------------------------------------------
    # Conversion mm -> inches (LayOut travaille en pouces)
    # ------------------------------------------------------------
    def self.mm_to_inch(mm)
      mm.to_f / 25.4
    end

    # ------------------------------------------------------------
    # Calcul du point d'ancrage du label par rapport au viewport
    # ------------------------------------------------------------
    def self.label_anchor_point(bounds, cfg)
      offset_in = mm_to_inch(cfg["offset_mm"].to_f)
      cx = (bounds.upper_left.x + bounds.lower_right.x) / 2.0
      if cfg["anchor"] == "over"
        y = bounds.upper_left.y - offset_in
      else
        y = bounds.lower_right.y + offset_in
      end
      Geom::Point2d.new(cx, y)
    end

    # ------------------------------------------------------------
    # Creation d'un FormattedText : signature variable selon les
    # versions LayOut, on tente plusieurs combinaisons.
    # ------------------------------------------------------------
    def self.make_formatted_text(anchor_pt, text, cfg)
      anchor_type = if cfg["anchor"] == "over"
                      Layout::FormattedText::ANCHOR_TYPE_BOTTOM_CENTER
                    else
                      Layout::FormattedText::ANCHOR_TYPE_TOP_CENTER
                    end
      text_str = text.to_s

      rect_w = mm_to_inch(40.0)
      rect_h = mm_to_inch(8.0)
      rect = Geom::Bounds2d.new(
        anchor_pt.x - rect_w / 2.0, anchor_pt.y,
        anchor_pt.x + rect_w / 2.0, anchor_pt.y + rect_h
      )

      attempts = [
        [text_str, anchor_pt, anchor_type],
        [text_str, rect, anchor_type],
        [text_str, rect],
        [text_str, anchor_pt],
        [text_str],
        [anchor_pt, text_str, anchor_type],
        [rect, text_str, anchor_type],
        [anchor_pt, anchor_type, text_str]
      ]

      last_err = nil
      attempts.each do |args|
        begin
          return Layout::FormattedText.new(*args)
        rescue ArgumentError, TypeError, NoMethodError => e
          last_err = e
          next
        end
      end

      if Layout::FormattedText.respond_to?(:plain_text)
        begin
          return Layout::FormattedText.plain_text(rect, text_str)
        rescue StandardError => e
          last_err = e
        end
      end

      raise "Layout::FormattedText.new : aucune signature compatible (#{last_err && last_err.message})"
    end

    # ------------------------------------------------------------
    # Application de la typo (police + taille).
    # ------------------------------------------------------------
    def self.apply_text_style(text_entity, cfg)
      family = cfg["font_family"].to_s
      size_pts = cfg["font_size"].to_f
      return unless text_entity.respond_to?(:style)

      apply = lambda do |style|
        style.font_family = family if style.respond_to?(:font_family=) && !family.empty?
        if style.respond_to?(:font_size=) && size_pts > 0
          style.font_size = size_pts
        end
        style
      end

      begin
        if text_entity.respond_to?(:apply_style) && text_entity.method(:style).arity != 0
          style = text_entity.style(0)
          apply.call(style)
          text_entity.apply_style(style)
        else
          style = text_entity.style
          apply.call(style)
          text_entity.style = style if text_entity.respond_to?(:style=)
        end
      rescue StandardError
      end
    end

    # ------------------------------------------------------------
    # Coeur du traitement
    # ------------------------------------------------------------
    def self.process_document(doc, cfg)
      stats = { :total => 0, :labeled => 0, :perspective => 0, :skipped => 0, :pages => 0 }

      layer = find_or_create_layer(doc)
      purge_layer(doc, layer)

      viewports = []
      each_entity(doc) do |e, page_from_iter|
        next unless e.is_a?(Layout::SketchUpModel)
        viewports << [e, page_from_iter]
      end
      stats[:total] = viewports.size

      pages_seen = {}

      viewports.each do |vp, page_from_iter|
        info = viewport_info(vp)
        page = info[:page] || page_from_iter
        pages_seen[page.object_id] = true if page
        bounds = info[:bounds]
        next unless bounds

        is_perspective = !info[:orthogonal]

        if is_perspective && cfg["ignore_perspective"]
          stats[:skipped] += 1
          next
        end

        text_str = build_label_text(info[:scale], cfg, perspective: is_perspective, scene_name: info[:scene])
        next if text_str.nil? || text_str.empty?

        anchor_pt = label_anchor_point(bounds, cfg)
        text = make_formatted_text(anchor_pt, text_str, cfg)
        apply_text_style(text, cfg)

        if page
          doc.add_entity(text, layer, page)
        else
          begin
            doc.add_entity(text, layer)
          rescue ArgumentError
            doc.add_entity(text, layer, doc.pages.first)
          end
        end

        if is_perspective
          stats[:perspective] += 1
        else
          stats[:labeled] += 1
        end
      end

      stats[:pages] = pages_seen.size
      stats
    end

    # ------------------------------------------------------------
    # Selection / sauvegarde
    # ------------------------------------------------------------
    def self.choose_input_file
      UI.openpanel(I18n.t("msg.choose_input"), "", "LayOut|*.layout||")
    end

    def self.choose_output_file(input_path)
      ans = UI.messagebox(I18n.t("msg.save_question"), MB_YESNOCANCEL)
      case ans
      when IDYES
        input_path
      when IDNO
        dir  = File.dirname(input_path)
        base = File.basename(input_path, ".layout")
        suggestion = "#{base}#{I18n.t("msg.copy_suffix")}.layout"
        UI.savepanel(I18n.t("msg.save_copy"), dir, suggestion)
      else
        nil
      end
    end

    # ------------------------------------------------------------
    # Entrees
    # ------------------------------------------------------------
    def self.run
      config # garantit que I18n.set_locale a ete fait
      unless defined?(Layout::Document)
        UI.messagebox(I18n.t("msg.no_layout_api"))
        return
      end
      show_dialog
    end

    def self.run_with_config(cfg)
      input_path = choose_input_file
      return unless input_path
      unless File.exist?(input_path)
        UI.messagebox(format(I18n.t("msg.file_not_found"), input_path))
        return
      end

      doc = nil
      begin
        doc = Layout::Document.open(input_path)
      rescue ArgumentError => e
        UI.messagebox(format(I18n.t("msg.cant_open"), input_path, e.message))
        return
      rescue StandardError => e
        UI.messagebox(format(I18n.t("msg.open_error"), e.message))
        return
      end

      stats = nil
      begin
        stats = process_document(doc, cfg)
      rescue StandardError => e
        UI.messagebox(format(I18n.t("msg.process_error"), e.message, e.backtrace.first(5).join("\n")))
        return
      end

      if stats[:total] == 0
        UI.messagebox(I18n.t("msg.no_views"))
        return
      end

      output_path = choose_output_file(input_path)
      unless output_path
        UI.messagebox(I18n.t("msg.no_save"))
        return
      end

      begin
        doc.save(output_path)
      rescue ArgumentError => e
        UI.messagebox(format(I18n.t("msg.cant_save"), output_path, e.message))
        return
      rescue StandardError => e
        UI.messagebox(format(I18n.t("msg.save_error"), e.message))
        return
      end

      UI.messagebox(I18n.t("msg.summary") % {
        :total       => stats[:total],
        :labeled     => stats[:labeled],
        :perspective => stats[:perspective],
        :skipped     => stats[:skipped],
        :pages       => stats[:pages],
        :path        => output_path
      })
    end

    # ------------------------------------------------------------
    # HtmlDialog
    # ------------------------------------------------------------
    def self.show_dialog
      if @dialog && @dialog.visible?
        @dialog.bring_to_front
        return
      end

      @dialog = UI::HtmlDialog.new(
        :dialog_title    => I18n.t("dialog.title"),
        :preferences_key => PREF_KEY,
        :scrollable      => true,
        :resizable       => true,
        :width           => 460,
        :height          => 620,
        :style           => UI::HtmlDialog::STYLE_DIALOG
      )
      @dialog.set_html(dialog_html)

      @dialog.add_action_callback("ready") do |_dlg, _arg|
        @dialog.execute_script("hydrate(#{config.to_json});")
      end

      # L'utilisateur change de langue dans le menu deroulant :
      # on sauvegarde la preference, on recharge I18n, et on
      # reconstruit entierement le HTML pour traduire l'UI.
      @dialog.add_action_callback("change_language") do |_dlg, lang|
        chosen = (lang.to_s == "auto" || lang.to_s == "fr" || lang.to_s == "en") ? lang.to_s : "auto"
        @config["language"] = chosen
        Sketchup.write_default(PREF_KEY, "language", chosen)
        I18n.set_locale(I18n.detect_locale(chosen))
        @dialog.set_html(dialog_html)
        # set_html declenche un nouveau "ready", l'hydrate reviendra automatiquement
      end

      @dialog.add_action_callback("save_and_run") do |_dlg, payload|
        cfg = parse_payload(payload)
        save_config(cfg)
        @dialog.close if @dialog
        UI.start_timer(0.1, false) { run_with_config(config) }
      end

      @dialog.add_action_callback("save_only") do |_dlg, payload|
        cfg = parse_payload(payload)
        save_config(cfg)
      end

      @dialog.add_action_callback("cancel") do |_dlg, _arg|
        @dialog.close if @dialog
      end

      @dialog.show
    end

    def self.parse_payload(payload)
      data = payload.is_a?(Hash) ? payload : (JSON.parse(payload) rescue {})
      cleaned = {}
      cleaned["format"]             = data["format"].to_s
      cleaned["font_family"]        = data["font_family"].to_s
      cleaned["font_size"]          = data["font_size"].to_f
      cleaned["anchor"]             = (data["anchor"].to_s == "over" ? "over" : "below")
      cleaned["offset_mm"]          = data["offset_mm"].to_f
      cleaned["ignore_perspective"] = (data["ignore_perspective"] == true || data["ignore_perspective"].to_s == "true")
      cleaned["perspective_text"]   = data["perspective_text"].to_s
      cleaned["scale_unit"]         = (data["scale_unit"].to_s == "decimal" ? "decimal" : "ratio")
      cleaned["show_scene"]         = (data["show_scene"] == true || data["show_scene"].to_s == "true")
      lang = data["language"].to_s
      cleaned["language"]           = %w[auto fr en].include?(lang) ? lang : "auto"
      cleaned
    end

    def self.dialog_html
      # On construit le HTML avec les traductions de la locale courante.
      # Les chaines sont injectees via interpolation Ruby standard.
      title       = I18n.t("dialog.heading")
      l_text      = I18n.t("dialog.text")
      l_format    = I18n.t("dialog.format")
      h_format    = I18n.t("dialog.format.help")
      l_unit      = I18n.t("dialog.scale_unit")
      l_ratio     = I18n.t("dialog.scale.ratio")
      l_decimal   = I18n.t("dialog.scale.decimal")
      l_persp     = I18n.t("dialog.persp_text")
      l_typo      = I18n.t("dialog.typo")
      l_font      = I18n.t("dialog.font")
      l_size      = I18n.t("dialog.size")
      l_position  = I18n.t("dialog.position")
      l_anchor    = I18n.t("dialog.anchor")
      l_below     = I18n.t("dialog.anchor.below")
      l_over      = I18n.t("dialog.anchor.over")
      l_offset    = I18n.t("dialog.offset")
      l_options   = I18n.t("dialog.options")
      l_ign_persp = I18n.t("dialog.ignore_persp")
      l_showscene = I18n.t("dialog.show_scene")
      h_showscene = I18n.t("dialog.show_scene.h")
      l_lang      = I18n.t("dialog.language")
      l_lang_auto = I18n.t("dialog.lang.auto")
      l_lang_fr   = I18n.t("dialog.lang.fr")
      l_lang_en   = I18n.t("dialog.lang.en")
      btn_cancel  = I18n.t("dialog.btn.cancel")
      btn_save    = I18n.t("dialog.btn.save")
      btn_run     = I18n.t("dialog.btn.run")

      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, Segoe UI, Arial, sans-serif; font-size: 12px;
                 margin: 12px; color: #222; }
          h2 { font-size: 14px; margin: 0 0 12px 0; }
          fieldset { border: 1px solid #ccc; border-radius: 4px; margin: 0 0 12px 0; padding: 8px 12px; }
          legend { padding: 0 6px; color: #555; font-weight: bold; }
          label { display: block; margin: 6px 0 2px; }
          input[type=text], input[type=number], select {
            width: 100%; box-sizing: border-box; padding: 4px 6px;
            border: 1px solid #bbb; border-radius: 3px; font-size: 12px;
          }
          .row { display: flex; gap: 10px; }
          .row > div { flex: 1; }
          .check { margin: 8px 0; }
          .help { color: #777; font-size: 11px; margin-top: 2px; }
          .actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 16px; }
          button { padding: 6px 14px; border-radius: 3px; border: 1px solid #888;
                   background: #f3f3f3; cursor: pointer; font-size: 12px; }
          button.primary { background: #2c7be5; color: white; border-color: #2c7be5; }
          button.primary:hover { background: #1f5fbd; }
          .credits { margin-top: 14px; color: #999; font-size: 10px; text-align: right; }
          .lang-bar { display: flex; align-items: center; gap: 8px; margin-bottom: 10px;
                      padding: 6px 8px; background: #f6f6f6; border-radius: 3px; }
          .lang-bar label { margin: 0; color: #555; }
          .lang-bar select { width: auto; flex: 0 0 auto; }
        </style>
        </head>
        <body>
          <h2>#{title}</h2>

          <div class="lang-bar">
            <label for="language">#{l_lang} :</label>
            <select id="language" onchange="onChangeLanguage()">
              <option value="auto">#{l_lang_auto}</option>
              <option value="fr">#{l_lang_fr}</option>
              <option value="en">#{l_lang_en}</option>
            </select>
          </div>

          <fieldset>
            <legend>#{l_text}</legend>
            <label>#{l_format}</label>
            <input type="text" id="format">
            <div class="help">#{h_format}</div>

            <div class="row">
              <div>
                <label>#{l_unit}</label>
                <select id="scale_unit">
                  <option value="ratio">#{l_ratio}</option>
                  <option value="decimal">#{l_decimal}</option>
                </select>
              </div>
              <div>
                <label>#{l_persp}</label>
                <input type="text" id="perspective_text">
              </div>
            </div>
          </fieldset>

          <fieldset>
            <legend>#{l_typo}</legend>
            <div class="row">
              <div>
                <label>#{l_font}</label>
                <select id="font_family">
                  <option>Arial</option>
                  <option>Helvetica</option>
                  <option>Calibri</option>
                  <option>Times New Roman</option>
                  <option>Courier New</option>
                  <option>Verdana</option>
                  <option>Tahoma</option>
                </select>
              </div>
              <div>
                <label>#{l_size}</label>
                <input type="number" id="font_size" min="4" max="200" step="0.5">
              </div>
            </div>
          </fieldset>

          <fieldset>
            <legend>#{l_position}</legend>
            <div class="row">
              <div>
                <label>#{l_anchor}</label>
                <select id="anchor">
                  <option value="below">#{l_below}</option>
                  <option value="over">#{l_over}</option>
                </select>
              </div>
              <div>
                <label>#{l_offset}</label>
                <input type="number" id="offset_mm" min="0" max="500" step="0.5">
              </div>
            </div>
          </fieldset>

          <fieldset>
            <legend>#{l_options}</legend>
            <div class="check">
              <label><input type="checkbox" id="ignore_perspective"> #{l_ign_persp}</label>
            </div>
            <div class="check">
              <label><input type="checkbox" id="show_scene"> #{l_showscene}</label>
              <div class="help">#{h_showscene}</div>
            </div>
          </fieldset>

          <div class="actions">
            <button onclick="onCancel()">#{btn_cancel}</button>
            <button onclick="onSaveOnly()">#{btn_save}</button>
            <button class="primary" onclick="onSaveAndRun()">#{btn_run}</button>
          </div>

          <div class="credits">(c) Jacques Vernet</div>

        <script>
          function hydrate(cfg) {
            document.getElementById('format').value             = cfg.format || '';
            document.getElementById('scale_unit').value         = cfg.scale_unit || 'ratio';
            document.getElementById('perspective_text').value   = cfg.perspective_text || 'NTS';
            document.getElementById('font_family').value        = cfg.font_family || 'Arial';
            document.getElementById('font_size').value          = cfg.font_size || 10;
            document.getElementById('anchor').value             = cfg.anchor || 'below';
            document.getElementById('offset_mm').value          = (cfg.offset_mm == null ? 5 : cfg.offset_mm);
            document.getElementById('ignore_perspective').checked = !!cfg.ignore_perspective;
            document.getElementById('show_scene').checked        = !!cfg.show_scene;
            document.getElementById('language').value           = cfg.language || 'auto';
          }
          function collect() {
            return {
              format:             document.getElementById('format').value,
              scale_unit:         document.getElementById('scale_unit').value,
              perspective_text:   document.getElementById('perspective_text').value,
              font_family:        document.getElementById('font_family').value,
              font_size:          parseFloat(document.getElementById('font_size').value || '10'),
              anchor:             document.getElementById('anchor').value,
              offset_mm:          parseFloat(document.getElementById('offset_mm').value || '5'),
              ignore_perspective: document.getElementById('ignore_perspective').checked,
              show_scene:         document.getElementById('show_scene').checked,
              language:           document.getElementById('language').value
            };
          }
          function onChangeLanguage() {
            sketchup.change_language(document.getElementById('language').value);
          }
          function onSaveAndRun() { sketchup.save_and_run(collect()); }
          function onSaveOnly()   { sketchup.save_only(collect()); }
          function onCancel()     { sketchup.cancel(); }
          window.addEventListener('load', function() { sketchup.ready(); });
        </script>
        </body>
        </html>
      HTML
    end

    # ------------------------------------------------------------
    # Toolbar + menu (une seule fois)
    # IMPORTANT : on n'utilise pas __FILE__ ici (non fiable une fois chiffre).
    # PLUGIN_DIR est defini dans le loader (qui reste en .rb clair).
    # ------------------------------------------------------------
    unless defined?(@ui_loaded) && @ui_loaded
      # Initialise la locale avant de creer le menu/toolbar
      _initial_lang = Sketchup.read_default(PREF_KEY, "language", "auto")
      I18n.set_locale(I18n.detect_locale(_initial_lang))

      icon_path = File.join(PLUGIN_DIR, "icons", "scale_labeler.png")

      cmd = UI::Command.new(I18n.t("menu.command")) { run }
      cmd.tooltip         = I18n.t("menu.tooltip")
      cmd.status_bar_text = I18n.t("menu.statusbar")
      if File.exist?(icon_path)
        cmd.small_icon = icon_path
        cmd.large_icon = icon_path
      end

      begin
        toolbar = UI::Toolbar.new(I18n.t("toolbar.name"))
        toolbar.add_item(cmd)
        toolbar.show
      rescue StandardError
      end

      begin
        plugins_menu = UI.menu("Plugins")
        plugins_menu.add_item(cmd) if plugins_menu
      rescue StandardError
      end

      @ui_loaded = true
    end

  end
end
