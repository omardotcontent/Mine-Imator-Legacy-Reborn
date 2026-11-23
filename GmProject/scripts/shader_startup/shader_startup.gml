/// shader_startup()

function shader_startup()
{
	globalvar shader_map, shader_texture_surface, shader_texture_filter_linear, shader_texture_filter_mipmap, shader_check_uniform;
	globalvar shader_texture_width, shader_texture_height;
	globalvar shader_blend_color, shader_blend_alpha;
	globalvar shader_clip_x, shader_clip_y, shader_clip_width, shader_clip_height, shader_clip_active;
	
	// clip
	shader_clip_x = 0
	shader_clip_y = 0
	shader_clip_width = 0
	shader_clip_height = 0
	shader_clip_active = false
	
	// Texture drawing
	globalvar shader_mask;
	shader_mask = false
	
	// Init shaders
	log("Shader init")
	log("shaders_are_supported", yesno(shaders_are_supported()))
	
	var err = false;
	if (!shaders_are_supported())
		err = true
	
	shader_check_uniform = false
	
	// Compiled?
	if (!err)
	{
		shader_map = ds_map_create()
		new_shader("shader_alpha_fix")
		new_shader("shader_alpha_test")
		new_shader("shader_blend")
		new_shader("shader_border")
		new_shader("shader_outline")
		new_shader("shader_palette")
		new_shader("shader_color_camera")
		new_shader("shader_color_fog")
		new_shader("shader_color_fog_lights")
		new_shader("shader_depth")
		new_shader("shader_depth_point")
		new_shader("shader_draw_texture")
		new_shader("shader_replace")
		new_shader("shader_replace_alpha")
		new_shader("shader_high_aa")
		new_shader("shader_high_dof")
		new_shader("shader_high_dof_coc")
		new_shader("shader_high_dof_coc_blur")
		new_shader("shader_high_fog")
		new_shader("shader_high_fog_apply")
		new_shader("shader_high_light_apply")
		new_shader("shader_high_light_desaturate")
		new_shader("shader_high_light_night")
		new_shader("shader_high_light_point")
		new_shader("shader_high_light_point_shadowless")
		new_shader("shader_high_light_spot")
		new_shader("shader_high_light_sun")
		new_shader("shader_high_ssao")
		new_shader("shader_high_ssao_blur")
		new_shader("shader_high_ssao_depth_normal")
		new_shader("shader_color_glow")
		new_shader("shader_high_bloom_threshold")
		new_shader("shader_add")
		new_shader("shader_blur")
		new_shader("shader_color_correction")
		new_shader("shader_vignette")
		new_shader("shader_noise")
		new_shader("shader_ca")
		new_shader("shader_distort")
		new_shader("shader_clip")
		new_shader("shader_high_glint")
		new_shader("shader_high_godrays")
		new_shader("shader_high_tonemap")
		new_shader("shader_high_ssr")
		new_shader("shader_high_contact_shadows")
		new_shader("shader_high_sun_color")
		new_shader("shader_high_lensflare")
		new_shader("shader_high_outline")
		new_shader("shader_high_retro")
		new_shader("shader_high_volumetric_lights")
		new_shader("shader_high_fx_motion")
		new_shader("shader_high_weather")
		
		shader_texture_surface = false
		shader_texture_filter_linear = false
		shader_texture_filter_mipmap = false
		
		shader_texture_width = 0
		shader_texture_height = 0
		
		with (obj_shader)
		{
			log(name + " compiled", yesno(shader_is_compiled(shader)))
			
			if (!shader_is_compiled(shader))
			{
				err = true
				break
			}
		}
	}
	
	if (err)
	{
		log("Shader compilation failed")
		log("Try updating your graphics drivers", drivers_url_get())
		if (show_question("Some shaders failed to compile.\nCheck that your graphics drivers are up-to-date and restart Mine-imator.\n\nOpen support article about updating graphics drivers?"))
			open_url(drivers_url_get())
		
		game_end()
		return false
	}
	
	// Set special uniforms
	with (shader_map[?shader_border])
	{
		new_shader_uniform("uTexSize")
		new_shader_uniform("uColor")
	}
	
	with (shader_map[?shader_outline])
	{
		new_shader_uniform("uTexSize")
	}
	
	with (shader_map[?shader_palette])
	{
		new_shader_sampler("uPalette")
		new_shader_sampler("uPaletteKey")
		new_shader_uniform("uPaletteSize")
	}
	
	with (shader_map[?shader_color_camera])
	{
		new_shader_uniform("uBrightness")
		new_shader_uniform("uRGBAdd")
		new_shader_uniform("uRGBSub")
		new_shader_uniform("uHSBAdd")
		new_shader_uniform("uHSBSub")
		new_shader_uniform("uHSBMul")
		new_shader_uniform("uMixColor")
	}
	
	with (shader_map[?shader_color_fog])
	{
		new_shader_uniform("uColorsExt")
		new_shader_uniform("uRGBAdd")
		new_shader_uniform("uRGBSub")
		new_shader_uniform("uHSBAdd")
		new_shader_uniform("uHSBSub")
		new_shader_uniform("uHSBMul")
		new_shader_uniform("uMixColor")
		new_shader_uniform("uIsSky")
		new_shader_uniform("uIsWater")
		new_shader_uniform("uRippleTime")
		new_shader_uniform("uWaterRipples")
		new_shader_uniform("uWaterRippleStrength")
		new_shader_uniform("uWaterRippleSpeed")
		new_shader_uniform("uWetness")
		new_shader_uniform("uWetnessRipples")
		new_shader_uniform("uSunDir")
		new_shader_uniform("uSkyColor")
		new_shader_uniform("uHorizonColor")
	}
	
	with (shader_map[?shader_color_fog_lights])
	{
		new_shader_sampler("uGlintTexture")
		new_shader_uniform("uGlintOffset")
		new_shader_uniform("uGlintSize")
		new_shader_uniform("uGlintEnabled")
		new_shader_uniform("uGlintStrength")
		
		new_shader_uniform("uIsGround")
		new_shader_uniform("uIsSky")
		new_shader_uniform("uColorsExt")
		new_shader_uniform("uRGBAdd")
		new_shader_uniform("uRGBSub")
		new_shader_uniform("uHSBAdd")
		new_shader_uniform("uHSBSub")
		new_shader_uniform("uHSBMul")
		new_shader_uniform("uMixColor")
		new_shader_uniform("uLightAmount")
		new_shader_uniform("uLightData")
		new_shader_uniform("uAmbientColor")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uBlockBrightness")
	}
	
	with (shader_map[?shader_depth])
	{
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
		new_shader_uniform("uSkipTranslucent")
	}
	
	with (shader_map[?shader_depth_point])
	{
		new_shader_uniform("uEye")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
	}
	
	with (shader_map[?shader_draw_texture])
		new_shader_uniform("uMask")
	
	with (shader_map[?shader_replace])
		new_shader_uniform("uReplaceColor")
	
	with (shader_map[?shader_replace_alpha])
		new_shader_uniform("uReplaceColor")
	
	with (shader_map[?shader_high_aa])
	{
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uPower")
		new_shader_uniform("uThreshold")
	}
	
	with (shader_map[?shader_high_dof])
	{
		new_shader_sampler("uBlurBuffer")
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uBlurSize")
		new_shader_uniform("uBias")
		new_shader_uniform("uThreshold")
		new_shader_uniform("uGain")
		new_shader_uniform("uFringe")
		new_shader_uniform("uFringeAngle")
		new_shader_uniform("uFringeStrength")
		new_shader_uniform("uSampleAmount")
		new_shader_uniform("uSamples")
		new_shader_uniform("uWeightSamples")
	}
	
	with (shader_map[?shader_high_dof_coc])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_uniform("uDepth")
		new_shader_uniform("uRange")
		new_shader_uniform("uFadeSize")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
	}
	
	with (shader_map[?shader_high_dof_coc_blur])
	{
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uPixelCheck")
	}
	
	with (shader_map[?shader_high_fog])
	{
		new_shader_uniform("uCameraPos")
		new_shader_uniform("uSunDir")
		new_shader_uniform("uHeightFogEnable")
		new_shader_uniform("uHeightFogHeight")
		new_shader_uniform("uHeightFogDensity")
	}
	
	with (shader_map[?shader_high_fog_apply])
	{
		new_shader_sampler("uFogBuffer")
		new_shader_uniform("uFogColor")
		new_shader_uniform("uFogScatter")
		new_shader_uniform("uFogScatterColor")
		new_shader_uniform("uHeightFogEnable")
		new_shader_uniform("uHeightFogColor")
	}
	
	with (shader_map[?shader_high_light_apply])
	{
		new_shader_uniform("uAmbientColor")
	}
	
	with (shader_map[?shader_high_light_desaturate])
	{
		new_shader_sampler("uShadowBuffer")
		new_shader_uniform("uAmount")
	}
	
	with (shader_map[?shader_high_light_night])
	{
		new_shader_sampler("uTextureMaterial")
		new_shader_sampler("uTextureNormal")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uBlockBrightness")
		new_shader_uniform("uUseNormalMap")
		new_shader_uniform("uMaterialFormat")
		new_shader_uniform("uDefaultEmissive")
		new_shader_uniform("uHemiEnable")
		new_shader_uniform("uHemiStrength")
		new_shader_uniform("uHemiSkyColor")
		new_shader_uniform("uHemiGroundColor")
		new_shader_uniform("uRimEnable")
		new_shader_uniform("uRimStrength")
		new_shader_uniform("uRimPower")
		new_shader_uniform("uRimColor")
	}
	
	with (shader_map[?shader_high_light_point])
	{
		new_shader_sampler("uTextureMaterial")
		new_shader_sampler("uTextureNormal")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uBlockBrightness")
		new_shader_uniform("uLightBleed")
		new_shader_uniform("uLightBleedStrength")
		new_shader_uniform("uIsSky")
		new_shader_uniform("uIsWater")
		new_shader_uniform("uLightAmount")
		new_shader_uniform("uLightPosition")
		new_shader_uniform("uLightColor")
		new_shader_uniform("uLightStrength")
		new_shader_uniform("uLightNear")
		new_shader_uniform("uLightFar")
		new_shader_uniform("uLightFadeSize")
		new_shader_sampler("uDepthBufferXp")
		new_shader_sampler("uDepthBufferXn")
		new_shader_sampler("uDepthBufferYp")
		new_shader_sampler("uDepthBufferYn")
		new_shader_sampler("uDepthBufferZp")
		new_shader_sampler("uDepthBufferZn")
		new_shader_uniform("uBlurQuality")
		new_shader_uniform("uBlurSize")
		new_shader_uniform("uShadowBias")
		new_shader_uniform("uShadowDarkness")
		new_shader_uniform("uBleedLight")
		new_shader_uniform("uSubsurfaceColor")
		new_shader_uniform("uUseNormalMap")
		new_shader_uniform("uMaterialFormat")
		new_shader_uniform("uRoughness")
		new_shader_uniform("uMetallic")
		new_shader_uniform("uDefaultEmissive")
		new_shader_uniform("uSpecularEnable")
		new_shader_uniform("uSpecularStrength")
		new_shader_uniform("uSpecularShininess")
		new_shader_uniform("uWetness")
		new_shader_uniform("uCelEnable")
		new_shader_uniform("uCelSteps")
		new_shader_uniform("uCelSmooth")
	}
	
	with (shader_map[?shader_high_light_point_shadowless])
	{
		new_shader_sampler("uTextureMaterial")
		new_shader_sampler("uTextureNormal")
		new_shader_uniform("uIsSky")
		new_shader_uniform("uLightAmount")
		new_shader_uniform("uLightData")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uBlockBrightness")
		new_shader_uniform("uLightBleed")
		new_shader_uniform("uLightBleedStrength")
		new_shader_uniform("uBleedLight")
		new_shader_uniform("uSubsurfaceColor")
		new_shader_uniform("uUseNormalMap")
		new_shader_uniform("uMaterialFormat")
		new_shader_uniform("uRoughness")
		new_shader_uniform("uMetallic")
		new_shader_uniform("uDefaultEmissive")
		new_shader_uniform("uSpecularEnable")
		new_shader_uniform("uSpecularStrength")
		new_shader_uniform("uSpecularShininess")
	}
	
	with (shader_map[?shader_high_light_spot])
	{
		new_shader_sampler("uTextureMaterial")
		new_shader_sampler("uTextureNormal")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uBlockBrightness")
		new_shader_uniform("uLightBleed")
		new_shader_uniform("uLightBleedStrength")
		new_shader_uniform("uIsSky")
		new_shader_uniform("uIsWater")
		new_shader_uniform("uLightAmount")
		new_shader_uniform("uLightMatrix")
		new_shader_uniform("uLightPosition")
		new_shader_uniform("uLightColor")
		new_shader_uniform("uLightStrength")
		new_shader_uniform("uLightNear")
		new_shader_uniform("uLightFar")
		new_shader_uniform("uLightFadeSize")
		new_shader_uniform("uLightSpotSharpness")
		new_shader_sampler("uDepthBuffer")
		new_shader_uniform("uBlurQuality")
		new_shader_uniform("uBlurSize")
		new_shader_uniform("uShadowBias")
		new_shader_uniform("uShadowDarkness")
		new_shader_uniform("uBleedLight")
		new_shader_uniform("uSubsurfaceColor")
		new_shader_uniform("uUseNormalMap")
		new_shader_uniform("uMaterialFormat")
		new_shader_uniform("uRoughness")
		new_shader_uniform("uMetallic")
		new_shader_uniform("uDefaultEmissive")
		new_shader_uniform("uSpecularEnable")
		new_shader_uniform("uSpecularStrength")
		new_shader_uniform("uSpecularShininess")
		new_shader_uniform("uWetness")
		new_shader_uniform("uCelEnable")
		new_shader_uniform("uCelSteps")
		new_shader_uniform("uCelSmooth")
	}
	
	with (shader_map[?shader_high_light_sun])
	{
		new_shader_sampler("uTextureMaterial")
		new_shader_sampler("uTextureNormal")
		new_shader_sampler("uTransColorBuffer")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uBlockBrightness")
		new_shader_uniform("uLightBleed")
		new_shader_uniform("uLightBleedStrength")
		new_shader_uniform("uIsGround")
		new_shader_uniform("uSunAt")
		new_shader_uniform("uIsSky")
		new_shader_uniform("uIsWater")
		new_shader_uniform("uLightMatrix")
		new_shader_uniform("uLightPosition")
		new_shader_uniform("uLightNear")
		new_shader_uniform("uLightFar")
		new_shader_uniform("uLightColor")
		new_shader_sampler("uDepthBuffer")
		new_shader_uniform("uBlurQuality")
		new_shader_uniform("uBlurSize")
		new_shader_uniform("uShadowBias")
		new_shader_uniform("uShadowDarkness")
		new_shader_uniform("uShadowTint")
		new_shader_uniform("uColoredShadows")
		new_shader_uniform("uColoredShadowsStrength")
		new_shader_uniform("uDiffuseBoost")
		new_shader_uniform("uBleedLight")
		new_shader_uniform("uSubsurfaceColor")
		new_shader_uniform("uUseNormalMap")
		new_shader_uniform("uMaterialFormat")
		new_shader_uniform("uRoughness")
		new_shader_uniform("uMetallic")
		new_shader_uniform("uDefaultEmissive")
		new_shader_uniform("uHemiEnable")
		new_shader_uniform("uHemiStrength")
		new_shader_uniform("uHemiSkyColor")
		new_shader_uniform("uHemiGroundColor")
		new_shader_uniform("uRimEnable")
		new_shader_uniform("uRimStrength")
		new_shader_uniform("uRimPower")
		new_shader_uniform("uRimColor")
		new_shader_uniform("uSpecularEnable")
		new_shader_uniform("uSpecularStrength")
		new_shader_uniform("uSpecularShininess")
		new_shader_sampler("uCloudTexture")
		new_shader_uniform("uCloudShadows")
		new_shader_uniform("uCloudShadowsStrength")
		new_shader_uniform("uCloudShadowsScale")
		new_shader_uniform("uCloudTileSize")
		new_shader_uniform("uCloudOffset")
		new_shader_uniform("uCloudHeight")
		new_shader_uniform("uSunDir")
		new_shader_uniform("uRippleTime")
		new_shader_uniform("uWaterRipples")
		new_shader_uniform("uWaterRippleStrength")
		new_shader_uniform("uWaterRippleSpeed")
		new_shader_uniform("uWetness")
		new_shader_uniform("uWetnessRipples")
		new_shader_uniform("uCelEnable")
		new_shader_uniform("uCelSteps")
		new_shader_uniform("uCelSmooth")
	}
	
	with (shader_map[?shader_high_ssao])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_sampler("uNormalBuffer")
		new_shader_sampler("uBrightnessBuffer")
		new_shader_sampler("uNoiseBuffer")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
		new_shader_uniform("uProjMatrix")
		new_shader_uniform("uProjMatrixInv")
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uKernel")
		new_shader_uniform("uSamples")
		new_shader_uniform("uRadius")
		new_shader_uniform("uPower")
		new_shader_uniform("uBias")
		new_shader_uniform("uColor")
	}
	
	with (shader_map[?shader_high_ssao_blur])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_sampler("uNormalBuffer")
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uPixelCheck")
	}
	
	with (shader_map[?shader_high_ssao_depth_normal])
	{
		new_shader_sampler("uTextureMaterial")
		new_shader_sampler("uTextureNormal")
		new_shader_uniform("uSSAOEnable")
		new_shader_uniform("uIsWater")
		new_shader_uniform("uIsGround")
		new_shader_uniform("uOutlineEnable")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uBlockBrightness")
		new_shader_uniform("uUseNormalMap")
		new_shader_uniform("uMaterialFormat")
		new_shader_uniform("uRoughness")
		new_shader_uniform("uMetallic")
		new_shader_uniform("uDefaultEmissive")
		new_shader_uniform("uRippleTime")
		new_shader_uniform("uWaterRipples")
		new_shader_uniform("uWaterRippleStrength")
		new_shader_uniform("uWaterRippleSpeed")
		new_shader_uniform("uWetness")
		new_shader_uniform("uWetnessRipples")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
	}
	
	with (shader_map[?shader_color_glow])
	{
		new_shader_sampler("uTextureMaterial")
		new_shader_uniform("uColorsExt")
		new_shader_uniform("uRGBAdd")
		new_shader_uniform("uRGBSub")
		new_shader_uniform("uHSBAdd")
		new_shader_uniform("uHSBSub")
		new_shader_uniform("uHSBMul")
		new_shader_uniform("uMixColor")
		new_shader_uniform("uGlow")
		new_shader_uniform("uGlowTexture")
		new_shader_uniform("uGlowColor")
		new_shader_uniform("uBlockGlow")
		new_shader_uniform("uBlockBrightness")
		new_shader_uniform("uGlowThreshold")
		new_shader_uniform("uUseMaterialMap")
		new_shader_uniform("uMaterialFormat")
		new_shader_uniform("uDefaultEmissive")
	}
	
	with (shader_map[?shader_high_bloom_threshold])
	{
		new_shader_uniform("uThreshold")
	}
	
	with (shader_map[?shader_add])
	{
		new_shader_sampler("uAddTexture")
		new_shader_uniform("uAmount")
		new_shader_uniform("uPower")
	}
	
	with (shader_map[?shader_blur])
	{
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uRadius")
		new_shader_uniform("uDirection")
		new_shader_uniform("uKernel")
		new_shader_uniform("uSamples")
	}
	
	with (shader_map[?shader_color_correction])
	{
		new_shader_uniform("uContrast")
		new_shader_uniform("uBrightness")
		new_shader_uniform("uSaturation")
		new_shader_uniform("uVibrance")
		new_shader_uniform("uColorBurn")
	}
	
	with (shader_map[?shader_vignette])
	{
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uRadius")
		new_shader_uniform("uSoftness")
		new_shader_uniform("uStrength")
		new_shader_uniform("uColor")
	}
	
	with (shader_map[?shader_noise])
	{
		new_shader_sampler("uNoiseBuffer")
		new_shader_uniform("uNoiseSize")
		new_shader_uniform("uStrength")
		new_shader_uniform("uSaturation")
		new_shader_uniform("uSize")
		new_shader_uniform("uScreenSize")
	}
	
	with (shader_map[?shader_ca])
	{
		new_shader_uniform("uBlurAmount")
		new_shader_uniform("uColorOffset")
		new_shader_uniform("uDistortChannels")
	}
	
	with (shader_map[?shader_distort])
	{
		new_shader_uniform("uDistortAmount")
		new_shader_uniform("uRepeatImage")
		new_shader_uniform("uZoomAmount")
	}
	
	with (shader_map[?shader_clip])
	{
		new_shader_uniform("uBox")
		new_shader_uniform("uScreenSize")
	}
	
	with (shader_map[?shader_high_glint])
	{
		new_shader_sampler("uGlintTexture")
		new_shader_uniform("uGlintOffset")
		new_shader_uniform("uGlintSize")
		new_shader_uniform("uGlintEnabled")
		new_shader_uniform("uGlintStrength")
	}
	
	with (shader_map[?shader_high_godrays])
	{
		new_shader_sampler("uOcclusionMask")
		new_shader_uniform("uSunScreenPos")
		new_shader_uniform("uSunColor")
		new_shader_uniform("uSamples")
		new_shader_uniform("uDensity")
		new_shader_uniform("uDecay")
		new_shader_uniform("uWeight")
		new_shader_uniform("uExposure")
		new_shader_uniform("uSunVisibility")
	}
	
	with (shader_map[?shader_high_tonemap])
	{
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uTonemapper")
		new_shader_uniform("uExposure")
		new_shader_uniform("uGamma")
		new_shader_uniform("uContrast")
		new_shader_uniform("uSaturation")
		new_shader_uniform("uVibrance")
		new_shader_uniform("uSharpen")
		new_shader_uniform("uTemperature")
		new_shader_uniform("uTint")
		new_shader_uniform("uLiftShadows")
		new_shader_uniform("uLiftMidtones")
		new_shader_uniform("uLiftHighlights")
		new_shader_uniform("uGlobalCA")
		new_shader_uniform("uGlobalGrain")
		new_shader_uniform("uTime")
		new_shader_uniform("uGlobalVignette")
		new_shader_uniform("uGlobalVignetteRadius")
		new_shader_uniform("uGlobalVignetteColor")
	}
	
	with (shader_map[?shader_high_ssr])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_sampler("uNormalBuffer")
		new_shader_sampler("uMaterialBuffer")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
		new_shader_uniform("uProjMatrix")
		new_shader_uniform("uProjMatrixInv")
		new_shader_uniform("uSteps")
		new_shader_uniform("uMaxDist")
		new_shader_uniform("uThickness")
		new_shader_uniform("uStrength")
		new_shader_uniform("uFresnel")
		new_shader_uniform("uWaterOnly")
		new_shader_uniform("uSkyColor")
		new_shader_uniform("uHorizonColor")
	}
	
	with (shader_map[?shader_high_contact_shadows])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_sampler("uNormalBuffer")
		new_shader_sampler("uMaterialBuffer")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
		new_shader_uniform("uProjMatrix")
		new_shader_uniform("uProjMatrixInv")
		new_shader_uniform("uSunViewDir")
		new_shader_uniform("uSteps")
		new_shader_uniform("uLength")
		new_shader_uniform("uThickness")
		new_shader_uniform("uStrength")
	}
	
	with (shader_map[?shader_high_lensflare])
	{
		new_shader_sampler("uOcclusionMask")
		new_shader_uniform("uSunScreenPos")
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uColor")
		new_shader_uniform("uIntensity")
		new_shader_uniform("uGhosts")
		new_shader_uniform("uHalo")
		new_shader_uniform("uStarburst")
		new_shader_uniform("uVisibility")
	}
	
	with (shader_map[?shader_high_outline])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_sampler("uNormalBuffer")
		new_shader_sampler("uMaterialBuffer")
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uThickness")
		new_shader_uniform("uDepthSens")
		new_shader_uniform("uNormalSens")
		new_shader_uniform("uOpacity")
		new_shader_uniform("uDistFadeEnable")
		new_shader_uniform("uDistFade")
		new_shader_uniform("uColor")
	}
	
	with (shader_map[?shader_high_retro])
	{
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uTime")
		new_shader_uniform("uPixelate")
		new_shader_uniform("uDither")
		new_shader_uniform("uColors")
		new_shader_uniform("uScanlines")
		new_shader_uniform("uCurvature")
		new_shader_uniform("uVHS")
	}
	
	with (shader_map[?shader_high_volumetric_lights])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
		new_shader_uniform("uProjMatrixInv")
		new_shader_uniform("uLightCount")
		new_shader_uniform("uSteps")
		new_shader_uniform("uIntensity")
		new_shader_uniform("uSpotDensity")
		new_shader_uniform("uPointRadius")
		new_shader_uniform("uLightData")
	}
	
	with (shader_map[?shader_high_fx_motion])
	{
		new_shader_sampler("uDepthBuffer")
		new_shader_uniform("uNear")
		new_shader_uniform("uFar")
		new_shader_uniform("uProjMatrixInv")
		new_shader_uniform("uViewInvMatrix")
		new_shader_uniform("uPrevViewProjMatrix")
		new_shader_uniform("uTime")
		new_shader_uniform("uMotionBlur")
		new_shader_uniform("uRadialBlur")
		new_shader_uniform("uSpeedLines")
		new_shader_uniform("uSpeedLinesRadius")
		new_shader_uniform("uSpeedLinesColor")
	}
	
	with (shader_map[?shader_high_weather])
	{
		new_shader_uniform("uScreenSize")
		new_shader_uniform("uTime")
		new_shader_uniform("uRain")
		new_shader_uniform("uSnow")
		new_shader_uniform("uWind")
		new_shader_uniform("uLensDrops")
	}
	
	return true
}
