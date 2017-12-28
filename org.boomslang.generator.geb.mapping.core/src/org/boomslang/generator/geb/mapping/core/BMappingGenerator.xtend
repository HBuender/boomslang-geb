package org.boomslang.generator.geb.mapping.core

import com.wireframesketcher.model.Button
import com.wireframesketcher.model.Combo
import com.wireframesketcher.model.DateField
import com.wireframesketcher.model.Table
import com.wireframesketcher.model.TextArea
import com.wireframesketcher.model.TextField
import com.wireframesketcher.model.Widget
import java.util.regex.Pattern
import org.boomslang.dsl.mapping.mapping.BMapping
import org.boomslang.dsl.mapping.mapping.BMappingPackage
import org.boomslang.dsl.mapping.mapping.BNlsLangDecl
import org.boomslang.dsl.mapping.mapping.BUrl
import org.boomslang.dsl.mapping.mapping.BWidgetMapping
import org.boomslang.dsl.mapping.mapping.LanguageEnum
import org.boomslang.dsl.mapping.mapping.MExpression
import org.boomslang.dsl.mapping.mapping.MNlsMultiLangExpr
import org.boomslang.dsl.mapping.mapping.MStringLiteral
import org.boomslang.generator.interfaces.IBoomAggregateGenerator
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.IFileSystemAccess

import static org.boomslang.generator.geb.mapping.ui.GebOutputConfigurationProvider.*

import static extension com.google.common.base.Strings.*
import com.wireframesketcher.model.Checkbox
import com.wireframesketcher.model.RadioButton
import com.wireframesketcher.model.Label
import com.wireframesketcher.model.Popup

class BMappingGenerator implements IBoomAggregateGenerator {

	override doGenerate(Resource resource, IFileSystemAccess fsa) {
		if (resource == null) {
			return
		}
		switch (pack : resource.contents.get(0)) {
			BMappingPackage: {
				pack.getBMapping?.generateBMapping(fsa)
			}
		}
	}

	def void generateBMapping(BMapping it, IFileSystemAccess fsa) {
		val screenName = it?.screen?.name
		if (screenName == null) {
			return
		}

		val matcher = Pattern.compile('''^(.*)\.(\w+)$''').matcher(screenName)
		if (!matcher.matches) {
			return
		}
		val screenPackage = matcher.group(1)
		val screenSimpleName = matcher.group(2)
		val screenDir = screenPackage.replaceAll('''\.''', "/")

		fsa.generateFile(
			'''«screenDir»/«screenSimpleName»Screen.groovy''',
			OUTPUT_CONFIG_GEB,
			compileBMapping(screenPackage)
		)

		fsa.generateFile(
			'''«screenDir»/«screenSimpleName»Screen.java''',
			OUTPUT_CONFIG_GEB,
			compileBMappingPageObject(screenPackage)
		)
		screen?.widgets.filter[!name.nullOrEmpty].forEach [ widget |
			fsa.generateFile(
				'''«screenDir»/widgets/«widget.widgetName».java''',
				OUTPUT_CONFIG_GEB,
				widget.compileWidget(screenPackage)
			)
		]

	}

	def widgetName(Widget it) {
		'''«name.toFirstUpper»«class.name.split("\\.").last.replace("Impl","").toFirstUpper»'''
	}

	def compileWidget(Widget it, String screenPackage) {
		'''
			package «screenPackage».widgets;
			
			public class «widgetName»{
				
				«compileWidgetMethods»
				
			}
			
		'''
	}

	def dispatch compileWidgetMethods(EObject it) {
		'''
			//«it.class.name» not supported
		 '''
	}

	def dispatch compileWidgetMethods(Button it) {
		'''
			public void click(){
				//Implement click
			}
			
			public String label(){
				//Implement label
				return "DefaultLabel";
			}
			«standard»
		 '''
	}

	def dispatch compileWidgetMethods(TextField it) {
		'''
			public void type(String text){
				//Implement type
			}
			
			public String getContent(){
				return "content";
			}
			«standard»
		 '''
	}

	def dispatch compileWidgetMethods(DateField it) {
		'''
			public void select(String date){
				//Implement type
			}
			
			public String getDate(){
				return "content";
			}
			«standard»
		 '''
	}

	def dispatch compileWidgetMethods(Table it) {
		'''
				public void selectCellWhere(String columnTitle,String value){
				//Selected
				}
				
				public String[] getValuesOfCellWhere(String columnTitle){
				return new String[]{"TableCellContent1","TableCellContent2"};
				}
			«standard»
		'''
	}
	
	def dispatch compileWidgetMethods(Label it){'''
		public String getContent(){
			return "LabelContent";
		}
		
		«standard»
	'''
		
	}

	def dispatch compileWidgetMethods(TextArea it) {
		'''
			public void type(String text){
						//Implement type
					}
					
					public String getContent(){
						return "content";
					}
					«standard»
				 '''
	}

	def dispatch compileWidgetMethods(Combo it) {
		'''
		public void select(String option){
			//Select option
		}
		
		«standard»
    '''
	}
	
	def dispatch compileWidgetMethods(Checkbox it){'''
		public void check(){
			//Checkbox checked
		}
	'''}
	
	def dispatch compileWidgetMethods(RadioButton it){'''
		public void select(){
			//RadioButton selected
		}
	'''}
	
		def dispatch compileWidgetMethods(Popup it){'''
		public void select(String entry){
			//Select Popup menu entry 
		}
	'''}

	def standard() {
		'''    		
			public boolean isVisible(){
				//Implement check on visible
				return true;
			}
			
			public boolean isEnabled(){
				//Implement checkenabled
				return true;
			}
			
			public boolean isEmpty(){
				//Implement empty
				return true;
			}
		'''

	}

	def compileBMappingPageObject(BMapping it, String screenPackage) {
		'''
			package «screenPackage»;
			
			«FOR widget : screen?.widgets.filter[!name.nullOrEmpty]»
				import «screenPackage».widgets.«widget.widgetName»;
			«ENDFOR»
			
			public class «it.screen?.name?.replaceFirst('''^.*\.(\w+)$''', "$1")»Screen {
			
			static String url = "«it.getBUrl.compileMappingUrl»";
			        
			static String label="«it.getBLabel.expression»";
			
			public boolean isVisible(){
				return true;
			}
			
			«FOR widget : screen?.widgets.filter[!name.nullOrEmpty]»
				public «widget.widgetName» get«widget.widgetName»(){
					return new «widget.widgetName»(); 
				}
			«ENDFOR»
			}
		'''
	}

	def compileBMapping(BMapping it, String screenPackage) '''
		package «screenPackage»
		
		class «it.screen?.name?.replaceFirst('''^.*\.(\w+)$''', "$1")»Screen extends org.boomslang.pages.BoomslangScreen {
		
			static url = "«it.getBUrl.compileMappingUrl»"
		
			static at = { waitFor { title == "«it.getBLabel.expression»" } }
		
			static content = {
				«FOR m : it.getBWidgetMapping»
					«m.compileBWidgetMapping()»
				«ENDFOR»
			}
		
		}
	'''

	def navigatorName(BWidgetMapping it) {
		it.widget.name + "Navigator"
	}

	def compileMappingUrl(BUrl it) '''«path»'''

	def compileBWidgetMapping(BWidgetMapping it) '''
		«it.widget.name.toFirstLower» «compileWidgetMappingNavigatorPart(it)»
	'''

	def compileWidgetMappingNavigatorPart(
		BWidgetMapping it
	) '''(required: true«compileWait») {«compileModule()»$("«it.
			locator»") }
	'''

	def compileWait(BWidgetMapping it) '''
	«IF widget.waitRequired» , wait:true«ENDIF»'''

	def compileModule(BWidgetMapping it) ''' module «it.widgetNavigator», '''

	def isWaitRequired(Widget widget) {
		!(widget instanceof TextField)
	}

	def dispatch CharSequence compileExp(Void it) ''''''

	def dispatch CharSequence compileExp(MExpression it) ''''''

	def dispatch CharSequence compileExp(MNlsMultiLangExpr it) {
		it.langDecl.map[compile].join
	}

	def compile(BNlsLangDecl it) {
		if (it.lang == LanguageEnum::EN) {
			it.expression.compileExp
		} else {
			return ""
		}
	}

	def dispatch CharSequence compileExp(MStringLiteral it) {
		return it.value
	}

	override doGenerate(ResourceSet input, IFileSystemAccess fsa) {
		// Not needed
	}

	override getShortDescription() {
		"Mapping Generation"
	}

}
