 /*
  ****************************************************************************** 
  * @attention
  *
  * <h2><center>&copy; COPYRIGHT 2013 STMicroelectronics</center></h2>
  *
  * Licensed under MCD-ST Liberty SW License Agreement V2, (the "License");
  * You may not use this file except in compliance with the License.
  * You may obtain a copy of the License at:
  *
  *        http://www.st.com/software_license_agreement_liberty_v2
  *
  * Unless required by applicable law or agreed to in writing, software 
  * distributed under the License is distributed on an "AS IS" BASIS, 
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
  *
  ******************************************************************************
  */

/*
 * This file was originally generated for the F40x series at 168MHz by ST's AN3988
 * core clock generator spreadsheet and then modified by Andy Brown to work with
 * the F429 using the HSI as the clock source.
 */

#include "config/stdperiph.h"


/*
 * These are the key constants for setting up the PLL using 16MHz HSI as the source
 */

enum {
  VECT_TAB_OFFSET = 0,      // Vector Table base offset field. This value must be a multiple of 0x200.
  PLL_M           = 16,     // PLL_VCO = (HSE_VALUE or HSI_VALUE / PLL_M) * PLL_N
  PLL_N           = 360,
  PLL_P           = 2,      // SYSCLK = PLL_VCO / PLL_P
  PLL_Q           = 8       // USB OTG FS, SDIO and RNG Clock =  PLL_VCO / PLL_Q (note 45MHz unsuitable for USB)
};


/*
 * core clock startup value and AHB constants
 */

uint32_t SystemCoreClock=180000000;
const uint8_t AHBPrescTable[16] = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 6, 7, 8, 9 };


/**
  * @brief  Configures the System clock source, PLL Multiplier and Divider factors,
  *         AHB/APBx prescalers and Flash settings
  * @Note   This function should be called only once the RCC clock configuration
  *         is reset to the default reset state (done in SystemInit() function).
  * @param  None
  * @retval None
  */

static void SetSysClock() {

  // At this stage the HSI is already enabled and used as System clock source
  // Select regulator voltage output Scale 1 mode, System frequency up to 168 MHz

  RCC->APB1ENR |= RCC_APB1ENR_PWREN;
  PWR->CR |= PWR_CR_VOS;

  RCC->CFGR |= RCC_CFGR_HPRE_DIV1;    // HCLK = SYSCLK / 1
  RCC->CFGR |= RCC_CFGR_PPRE2_DIV2;   // PCLK2 = HCLK / 2
  RCC->CFGR |= RCC_CFGR_PPRE1_DIV4;   // PCLK1 = HCLK / 1

  // Configure the main PLL

  RCC->PLLCFGR = PLL_M | (PLL_N << 6) | (((PLL_P >> 1) -1) << 16) | (RCC_PLLCFGR_PLLSRC_HSI) | (PLL_Q << 24);

  // Enable the main PLL and wait until ready

  RCC->CR |= RCC_CR_PLLON;
  while((RCC->CR & RCC_CR_PLLRDY)==0);

  // Enable the Over-drive to extend the clock frequency to 180 Mhz

  PWR->CR |= PWR_CR_ODEN;
  while((PWR->CSR & PWR_CSR_ODRDY)==0);

  PWR->CR |= PWR_CR_ODSWEN;
  while((PWR->CSR & PWR_CSR_ODSWRDY)==0);

  // Configure Flash prefetch, Instruction cache, Data cache and wait state

  FLASH->ACR = FLASH_ACR_PRFTEN | FLASH_ACR_ICEN |FLASH_ACR_DCEN |FLASH_ACR_LATENCY_5WS;

  // Select the main PLL as system clock source
  RCC->CFGR &= (uint32_t)((uint32_t)~(RCC_CFGR_SW));
  RCC->CFGR |= RCC_CFGR_SW_PLL;

  // Wait till the main PLL is used as system clock source
  while ((RCC->CFGR & (uint32_t)RCC_CFGR_SWS ) != RCC_CFGR_SWS_PLL);
}


/**
  * @brief  Setup the microcontroller system
  *         Initialize the Embedded Flash Interface, the PLL and update the 
  *         SystemFrequency variable.
  * @param  None
  * @retval None
  */

void SystemInit() {

  // FPU settings

  #if (__FPU_PRESENT == 1) && (__FPU_USED == 1)
    SCB->CPACR |= ((3UL << 10*2)|(3UL << 11*2));  /* set CP10 and CP11 Full Access */
  #endif

  // Reset the RCC clock configuration to the default reset state


  RCC->CR |= 1;               // Set HSION bit
  RCC->CFGR = 0x00000000;     // Reset CFGR register
  RCC->CR &= 0xFEF6FFFF;      // Reset HSEON, CSSON and PLLON bits
  RCC->PLLCFGR = 0x24003010;  // Reset PLLCFGR register
  RCC->CR &= 0xFFFBFFFF;      // Reset HSEBYP bit
  RCC->CIR = 0;               // Disable all interrupts */

  /*
   * Configure the System clock source, PLL Multiplier and Divider factors,
   * AHB/APBx prescalers and Flash settings
   */

  SetSysClock();

  SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET;     // Vector Table Relocation in Internal FLASH
}


/**
 * Update the core clock. This is cut down from the generic version to only
 * work for PLL clock source with HSI
 */

void SystemCoreClockUpdate() {

  uint32_t tmp,pllvco,pllp,pllm;

  /*
   * PLL_VCO = (HSE_VALUE or HSI_VALUE / PLL_M) * PLL_N
   * SYSCLK = PLL_VCO / PLL_P
   */
  pllm = RCC->PLLCFGR & RCC_PLLCFGR_PLLM;
  pllvco = (HSI_VALUE / pllm) * ((RCC->PLLCFGR & RCC_PLLCFGR_PLLN) >> 6);
  pllp = (((RCC->PLLCFGR & RCC_PLLCFGR_PLLP) >>16) + 1 ) *2;

  SystemCoreClock = pllvco/pllp;

  // Compute HCLK frequency. Get HCLK prescaler

  tmp = AHBPrescTable[((RCC->CFGR & RCC_CFGR_HPRE) >> 4)];
  SystemCoreClock >>= tmp;
}

