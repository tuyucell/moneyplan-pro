package com.turgayyucel.invest_guide

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data from SharedPreferences (set by Flutter)
                val priceBist = widgetData.getString("price_bist", "9.100,50")
                val changeBist = widgetData.getString("change_bist", "+1.2%")
                val priceUsd = widgetData.getString("price_usd", "32.50")
                val changeUsd = widgetData.getString("change_usd", "+0.1%")
                val priceGold = widgetData.getString("price_gold", "2.450")
                val changeGold = widgetData.getString("change_gold", "+0.5%")

                setTextViewText(R.id.price_bist, priceBist)
                setTextViewText(R.id.change_bist, changeBist)
                setTextViewText(R.id.price_usd, priceUsd)
                setTextViewText(R.id.change_usd, changeUsd)
                setTextViewText(R.id.price_gold, priceGold)
                setTextViewText(R.id.change_gold, changeGold)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
