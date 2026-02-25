package android.src.main.kotlin.com.samsung.flutter.sdk.samsungpay.v2.samsung_pay_sdk_flutter.pojo

import android.os.Bundle
import com.google.gson.Gson
import com.google.gson.JsonArray
import com.google.gson.JsonObject
import com.google.gson.annotations.SerializedName
import com.samsung.android.sdk.samsungpay.v2.SpaySdk
import com.samsung.android.sdk.samsungpay.v2.SpaySdk.Brand
import com.samsung.android.sdk.samsungpay.v2.payment.sheet.SheetItem
import com.samsung.flutter.sdk.samsungpay.v2.samsung_pay_sdk_flutter.pojo.SheetItemPojo

data class RequestCardInfoPojo(

    @field:SerializedName("brandList")
    val data: JsonArray? = null,

    ){
    fun getBrandList(): ArrayList<SpaySdk.Brand> {
        val brandList = java.util.ArrayList<SpaySdk.Brand>()

        for (i in 0 until data?.size()!!) {
            val brand = data[i].asString

            if(brand == Brand.VISA.name)
            {
                brandList.add(SpaySdk.Brand.VISA)
            }
            else if(brand == Brand.MASTERCARD.name)
            {
                brandList.add(SpaySdk.Brand.MASTERCARD)
            }
            else if(brand == Brand.AMERICANEXPRESS.name)
            {
                brandList.add(SpaySdk.Brand.AMERICANEXPRESS)
            }
            else if(brand  == Brand.CHINAUNIONPAY.name)
            {
                brandList.add(SpaySdk.Brand.CHINAUNIONPAY)
            }
            else if(brand  == Brand.DISCOVER.name)
            {
                brandList.add(SpaySdk.Brand.DISCOVER)
            }
            else if(brand  == Brand.ECI.name)
            {
                brandList.add(SpaySdk.Brand.ECI)
            }
            else if(brand  == Brand.PAGOBANCOMAT.name)
            {
                brandList.add(SpaySdk.Brand.PAGOBANCOMAT)
            }
            else if(brand == Brand.MADA.name)
            {
                brandList.add(SpaySdk.Brand.MADA)
            }
        }
        return brandList
    }
}