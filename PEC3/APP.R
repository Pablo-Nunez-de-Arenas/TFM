# Lista de librerÃÂ­as requeridas
librerias <- c("ggplot2", "caret", "shiny", "shinydashboard")

# Verificar si las librerÃÂ­as estÃÂ¡n instaladas y cargarlas
for (libreria in librerias) {
  if (!requireNamespace(libreria, quietly = TRUE)) {
    install.packages(libreria)
  }
  library(libreria, character.only = TRUE)
}


# CREACIÓN DE LA APP
# DiseÃ±o de la APP
ui <- dashboardPage(
  # Encabezado de la aplicación
  dashboardHeader(title = "Predictor de CKD"),
  dashboardSidebar(
    sidebarMenu(
      # Opciónn de menú para la página de predicciones
      menuItem("Predicciones", tabName = "pagina1"),
      # Opciónn de menú para la página de visualización de datos
      menuItem("Visualización de datos", tabName = "pagina2")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        # Contenido de la página de predicciones
        tabName = "pagina1",
        fluidPage(
          # Panel de título para el ingreso de datos
          titlePanel("Ingreso de datos:"),
          sidebarLayout(
            sidebarPanel(
              # Ventana de seleción para los niveles de la variable "Urea en sangre"
              selectInput("var1", "Urea en sangre", choices = c("Normal" = 0, "Anormal" = 1)),
              # Ventana para hemoglobina en sangre
              selectInput("var2", "Hemoglobina en sangre", choices = c("Baja" = 0, "Normal" = 1, "Alta" = 2)),
              # Ventana para el recuento de globulos rojos
              selectInput("var3", "Recuento de glóbulos rojos", choices = c("Bajo" = 0, "Normal" = 1, "Alto" = 2))
            ),
            mainPanel(
              # Panel de título para la predicción
              titlePanel("Predicción:"),
              # Salida de texto para mostrar el resultado de la predicción
              verbatimTextOutput("resultado"),
              fluidRow(
                # Esta parte del código aÃ±ade la información relativa a que valores corresponden a cada nivel de cada variable
                column(12, h4("Notas:")),
                column(4,
                       # Niveles de urea en sangre
                       h5("Urea en sangre:"),
                       HTML("<ul>
                          <li>Normal: &lt; 48.1 mg/dl</li>
                          <li>Anormal: &gt; 48.1 mg/dl</li>
                        </ul>")
                ),
                column(4,
                       # Niveles de hemoglobina
                       h5("Hemoglobina en sangre:"),
                       HTML("<ul>
                          <li>Baja: &lt; 12.6 g/dl</li>
                          <li>Normal: 12.6 - 17.9 g/dl</li>
                          <li>Alta: &gt; 17.9 g/dl</li>
                        </ul>")
                ),
                column(4,
                       # Recuento de globulos rojos
                       h5("Recuento de glóbulos rojos:"),
                       HTML("<ul>
                          <li>Bajo: &lt; 2.69 - 4.46 mill/mm3</li>
                          <li>Normal: 4.46 - 5.05 mill/mm3</li>
                          <li>Alto: &gt; 5.05 mill/mm3</li>
                        </ul>")
                )
              ),
              # Esta parte de código se encarga de añadir el mensaje que informa de que esto no es un diagnóstico real y proporcione links con info adicional
              fluidRow(
                column(12,
                       div(
                         style = "background-color: #f8f9fa; padding: 10px; margin-top: 20px; text-align: center;",
                         "Importante: Este sistema de predicción proporciona estimaciones basadas en datos recopilados. No debe considerarse como un diagnóstico oficial. Si tiene preocupaciones sobre su salud renal, le recomendamos encarecidamente que busque la evaluación de un especialista médico capacitado. Solo un profesional de la salud puede proporcionar un diagnóstico preciso y brindarle el tratamiento adecuado en funciónn de su situación médica única."
                       ),
                       div(
                         style = "background-color: #f8f9fa; padding: 10px; margin-top: 20px; text-align: center;",
                         "Para obtener más información sobre la enfermedad renal crónica, puede consultar los siguientes enlaces:",
                         tags$ul(
                           tags$li(
                             tags$a(href = "https://www.cdc.gov/kidneydisease/basics.html", target = "_blank", "cdc.gov/kidneydisease/basics.html")
                           ),
                           tags$li(
                             tags$a(href = "https://www.nhs.uk/conditions/kidney-disease/", target = "_blank", "nhs.uk/conditions/kidney-disease/")
                           ),
                           tags$li(
                             tags$a(href = "https://www.youtube.com/watch?v=OVk4YXwJp98&ab_channel=MayoClinic", target = "_blank", "youtube.com/watch?v=OVk4YXwJp98")
                           ),
                           tags$li(
                             tags$a(href = "https://www.youtube.com/watch?v=XqsnI_PBKRI&ab_channel=MayoClinic", target = "_blank", "youtube.com/watch?v=XqsnI_PBKRI")
                           )
                         )
                       )
                )
              )
            )
          )
        )
      ),
      tabItem(
        # Contenido de la página de visualización de datos
        tabName = "pagina2",
        fluidPage(
          # Añadimos título
          titlePanel("Visualización de los datos que conforman el modelo:"),
          tags$div(
            # Explicación de la utilidad de la página
            style = "background-color: #f8f9fa; padding: 10px; margin-bottom: 20px;",
            "Esta página permite visualizar las variables utilizadas para la creación del modelo y la relación de cada variable con el resto."
          ),
          # Seleccionamos la variable 1 a visualizar
          selectInput("variable", "Variable 1:", choices = c("Diagnóstico" = "affected", "Urea en sangre" = "bu_new", "Hemoglobina en sangre" = "hemo_new", "Recuento de glóbulos rojos" = "rbcc_new")),
          # Variable 2
          selectInput("variable_fill", "Variable 2:", choices = c("Diagnóstico" = "affected", "Urea en sangre" = "bu_new", "Hemoglobina en sangre" = "hemo_new", "Recuento de glóbulos rojos" = "rbcc_new")),
          # Salida de gráfico para mostrar la visualización de datos
          plotOutput("grafico")
        )
      )
    )
  )
)

# Lógica de la APP
server <- function(input, output) {
  
  # Importar datos:
  file1 <- "data_sinteticos.csv"
  data_sint <- read.csv(file1)
  
  # Dividir los datos en entrenamiento y test
  set.seed(1234)
  train <- data_sint[sample(nrow(data_sint), size = round(0.67 * nrow(data_sint)), replace = FALSE), ]
  test <- data_sint[sample(nrow(data_sint), size = round(0.33 * nrow(data_sint)), replace = FALSE), ]
  
  # Obtenemos las etiquetas
  datos_train_labels <- train[, 1]
  datos_test_labels <- test[, 1]
  
  # Quitamos las etiquetas de los set de entrenamiento y test
  train <- train[, -1]
  test <- test[, -1]
  
  # Configuramos un método de control del tuneado de los hiperparámetros.
  training_control <- trainControl(method = "cv",
                                   summaryFunction = defaultSummary,
                                   number = 5)
  
  # Entrenamos los modelos
  set.seed(123)
  knn <- train(train, as.factor(datos_train_labels),
               method = "knn",
               metric = "Accuracy",
               trControl = training_control,
               tuneGrid = data.frame(k = c(5, 8, 13, 17, 25, 30, 40)))
  
  # Usaremos el modelo guardado en $finalModel para hacer las predicciones
  knn.pred <- predict(knn$finalModel, newdata = test, type = "class")
  
  output$resultado <- renderText({
    # Creació n de un data frame con los valores de entrada
    datos <- data.frame(var1 = input$var1, var2 = input$var2, var3 = input$var3)
    # PredicciÃ³n utilizando el modelo KNN
    prediccion <- predict(knn$finalModel, newdata = datos)
    # Generación de texto de resultado
    paste0("El diagnóstico es ", ifelse(prediccion[2] > prediccion[1], paste("CKD con una probabilidad del", round(prediccion[2] * 100), "%"), paste("no CKD con una probabilidad del", round(prediccion[1] * 100), "%")))
    
  })
  
  # Generar el grÃ¡fico
  output$grafico <- renderPlot({
    # Asignamos una etiqueta a cada variable
    variable_label <- switch(input$variable,
                             "bu_new" = "Urea en sangre",
                             "hemo_new" = "Hemoglobina en sangre",
                             "rbcc_new" = "Recuento de glÃ³bulos rojos",
                             "affected" = "Affected")
    
    # Se preprocesa la variable sellecionada para que aparezca correctamente en la leyenda del gráfico
    if (input$variable_fill == "affected") {
      data_sint$variable_fill <- factor(ifelse(data_sint$affected == 0, "No afectado", "Afectado"), levels = c("No afectado", "Afectado"))
      variable_fill_label <- "Affected"
    } else {
      data_sint$variable_fill <- factor(data_sint[, input$variable_fill], levels = c(0, 1, 2),
                                        labels = c("Bajo", "Normal", "Alto"))
      variable_fill_label <- switch(input$variable_fill,
                                    "bu_new" = "Urea en sangre",
                                    "hemo_new" = "Hemoglobina en sangre",
                                    "rbcc_new" = "Recuento de glóbulos rojos")
    }
    
    # Se genera el grÃ¡fico
    ggplot(data_sint, aes_string(x = input$variable, fill = "variable_fill")) +
      geom_bar(position = "fill", stat = "count") +
      labs(x = variable_label, y = "Proporción", fill = variable_fill_label) +
      scale_fill_manual(values = c("Bajo" = "green", "Normal" = "blue", "Alto" = "orange",
                                   "No afectado" = "blue", "Afectado" = "red")) +
      theme_minimal()
  })
  
}

# Activa la APP
shinyApp(ui, server)